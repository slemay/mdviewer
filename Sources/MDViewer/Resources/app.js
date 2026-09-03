// MDViewer Offline JavaScript Engine
(function () {
  'use strict';

  let currentSearchMatches = [];
  let currentSearchIndex = -1;

  // Configure Mermaid
  if (window.mermaid) {
    mermaid.initialize({
      startOnLoad: false,
      theme: 'default',
      securityLevel: 'loose',
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif'
    });
  }

  // Slugify helper for headings
  function slugify(text) {
    return text
      .toLowerCase()
      .trim()
      .replace(/<[^>]+>/g, '')
      .replace(/[^\w\s-]/g, '')
      .replace(/[\s_-]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  // Custom Marked Renderer
  const renderer = new marked.Renderer();
  let headingCounts = {};

  // Headings with stable IDs & duplicate count support
  renderer.heading = function (text, level) {
    const headingText = typeof text === 'object' ? text.text : text;
    const headingLevel = typeof text === 'object' ? text.depth : level;
    const baseSlug = slugify(headingText);
    let id = baseSlug;
    if (headingCounts[baseSlug] !== undefined) {
      headingCounts[baseSlug]++;
      id = `${baseSlug}-${headingCounts[baseSlug]}`;
    } else {
      headingCounts[baseSlug] = 0;
    }
    return `<h${headingLevel} id="${id}">${headingText}</h${headingLevel}>`;
  };

  // Code blocks: Highlight.js + Copy button + Mermaid support
  renderer.code = function (code, infostring) {
    const rawCode = typeof code === 'object' ? code.text : code;
    const lang = (typeof code === 'object' ? code.lang : infostring) || '';

    if (lang.trim().toLowerCase() === 'mermaid') {
      return `<div class="mermaid-wrapper"><div class="mermaid">${escapeHtml(rawCode)}</div></div>`;
    }

    let highlighted = escapeHtml(rawCode);
    if (window.hljs && lang && hljs.getLanguage(lang)) {
      try {
        highlighted = hljs.highlight(rawCode, { language: lang, ignoreIllegals: true }).value;
      } catch (err) {
        console.warn('Highlight.js error:', err);
      }
    } else if (window.hljs) {
      try {
        highlighted = hljs.highlightAuto(rawCode).value;
      } catch (err) {
        // fallback to escaped
      }
    }

    const langLabel = lang ? escapeHtml(lang) : 'code';
    const escapedCodeAttr = encodeURIComponent(rawCode);

    return `
      <div class="code-block-wrapper">
        <div class="code-block-header">
          <span class="code-block-lang">${langLabel}</span>
          <button class="copy-button" data-code="${escapedCodeAttr}" onclick="copyCodeBlock(this)">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
              <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
            </svg>
            <span>Copy</span>
          </button>
        </div>
        <pre><code class="language-${escapeHtml(lang)}">${highlighted}</code></pre>
      </div>
    `;
  };

  marked.use({ renderer: renderer, gfm: true, breaks: false });

  // Escape HTML utility
  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // GitHub Alert / Callout Transformer
  function transformGitHubAlerts(container) {
    const blockquotes = container.querySelectorAll('blockquote');
    const alertTypes = ['NOTE', 'TIP', 'IMPORTANT', 'WARNING', 'CAUTION'];

    blockquotes.forEach(bq => {
      const firstP = bq.querySelector('p:first-child');
      if (!firstP) return;

      const text = firstP.textContent.trim();
      for (const type of alertTypes) {
        const prefix = `[!${type}]`;
        if (text.startsWith(prefix)) {
          const typeLower = type.toLowerCase();
          const alertDiv = document.createElement('div');
          alertDiv.className = `markdown-alert markdown-alert-${typeLower}`;

          const titleDiv = document.createElement('div');
          titleDiv.className = 'markdown-alert-title';
          titleDiv.textContent = type.charAt(0) + type.slice(1).toLowerCase();

          alertDiv.appendChild(titleDiv);

          // Remove the [!NOTE] text from first paragraph
          firstP.textContent = text.slice(prefix.length).trim();
          if (firstP.textContent.length === 0) {
            firstP.remove();
          }

          while (bq.firstChild) {
            alertDiv.appendChild(bq.firstChild);
          }
          bq.replaceWith(alertDiv);
          break;
        }
      }
    });
  }

  // Intercept links to send external URLs to macOS
  document.addEventListener('click', function (e) {
    const link = e.target.closest('a');
    if (!link) return;

    const href = link.getAttribute('href');
    if (!href) return;

    if (href.startsWith('http://') || href.startsWith('https://') || href.startsWith('mailto:')) {
      e.preventDefault();
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.openExternalURL) {
        window.webkit.messageHandlers.openExternalURL.postMessage(href);
      } else {
        window.open(href, '_blank');
      }
    } else if (href.startsWith('#')) {
      e.preventDefault();
      const targetId = href.substring(1);
      window.scrollToHeading(targetId);
    }
  });

  // Global helper for code block copying
  window.copyCodeBlock = function (button) {
    const encoded = button.getAttribute('data-code');
    if (!encoded) return;
    const text = decodeURIComponent(encoded);

    navigator.clipboard.writeText(text).then(() => {
      const span = button.querySelector('span');
      const originalText = span.textContent;
      span.textContent = 'Copied!';
      button.style.color = '#1a7f37';
      button.style.borderColor = '#1a7f37';

      setTimeout(() => {
        span.textContent = originalText;
        button.style.color = '';
        button.style.borderColor = '';
      }, 1800);
    }).catch(err => {
      console.error('Failed to copy code:', err);
    });
  };

  // Main Render Function called from Swift
  window.renderMarkdown = function (rawMarkdown, preserveScroll) {
    headingCounts = {};
    const container = document.getElementById('content-container');
    if (!container) return;

    if (!rawMarkdown || rawMarkdown.trim() === '') {
      container.innerHTML = `
        <div class="empty-state">
          <div class="empty-state-icon">📄</div>
          <h2>No Document Open</h2>
          <p>Open a markdown file or drag one here to preview.</p>
        </div>
      `;
      return;
    }

    const previousScrollRatio = document.documentElement.scrollTop / (document.documentElement.scrollHeight - window.innerHeight || 1);
    const previousScrollY = window.scrollY;

    // 1. Render Markdown to HTML
    container.innerHTML = marked.parse(rawMarkdown);

    // 2. Transform GitHub Alerts
    transformGitHubAlerts(container);

    // 3. Render Math via KaTeX
    if (window.renderMathInElement) {
      try {
        renderMathInElement(container, {
          delimiters: [
            { left: '$$', right: '$$', display: true },
            { left: '$', right: '$', display: false },
            { left: '\\(', right: '\\)', display: false },
            { left: '\\[', right: '\\]', display: true }
          ],
          throwOnError: false
        });
      } catch (e) {
        console.warn('KaTeX render error:', e);
      }
    }

    // 4. Render Mermaid Diagrams
    if (window.mermaid) {
      try {
        mermaid.run({
          nodes: container.querySelectorAll('.mermaid')
        });
      } catch (e) {
        console.warn('Mermaid render error:', e);
      }
    }

    // 5. Restore scroll
    if (preserveScroll) {
      requestAnimationFrame(() => {
        window.scrollTo({
          top: previousScrollY,
          behavior: 'instant'
        });
      });
    }
  };

  // Theme Controller
  window.setTheme = function (themeName) {
    const html = document.documentElement;
    html.className = '';
    html.classList.add(`theme-${themeName}`);

    const lightCss = document.getElementById('highlight-light');
    const darkCss = document.getElementById('highlight-dark');

    const isDark = themeName === 'github-dark' || themeName === 'dracula' || themeName === 'nord' ||
      (themeName === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches);

    if (lightCss && darkCss) {
      lightCss.disabled = isDark;
      darkCss.disabled = !isDark;
    }

    // Update Mermaid theme if needed
    if (window.mermaid) {
      mermaid.initialize({
        startOnLoad: false,
        theme: isDark ? 'dark' : 'default'
      });
    }
  };

  // Font & Typography Controller
  window.setFont = function (fontType, fontSizePx) {
    const html = document.documentElement;
    if (fontType === 'serif') {
      html.style.setProperty('--current-font-family', 'var(--font-serif)');
    } else if (fontType === 'mono') {
      html.style.setProperty('--current-font-family', 'var(--font-mono)');
    } else {
      html.style.setProperty('--current-font-family', 'var(--font-sans)');
    }

    if (fontSizePx && fontSizePx > 0) {
      html.style.setProperty('--font-size-base', `${fontSizePx}px`);
      const scale = (fontSizePx / 16.0).toFixed(4);
      html.style.setProperty('--object-scale', scale);
    }
  };

  // Smart Heading Element Resolver
  // Resolves IDs whether they are exact, URL-encoded, single/double hyphenated (GFM),
  // matched by text slug, or matched by section prefix.
  window.findHeadingElement = function (targetId) {
    if (!targetId) return null;
    let decoded = targetId;
    try {
      decoded = decodeURIComponent(targetId).trim();
    } catch (e) {
      decoded = targetId.trim();
    }

    // 1. Direct ID match
    let el = document.getElementById(decoded) || document.getElementById(targetId);
    if (el) return el;

    // 2. Anchor name match
    try {
      el = document.querySelector(`a[name="${CSS.escape(decoded)}"]`) ||
           document.querySelector(`a[name="${CSS.escape(targetId)}"]`);
      if (el) return el;
    } catch (e) {}

    const allHeadings = Array.from(document.querySelectorAll('h1, h2, h3, h4, h5, h6'));
    const normTarget = decoded.toLowerCase().replace(/^-+|-+$/g, '');
    const cleanTarget = normTarget.replace(/-+/g, '-');
    const noHyphenTarget = normTarget.replace(/-/g, '');

    // 3. Normalized ID match (single hyphen vs double hyphen)
    for (const h of allHeadings) {
      const hNorm = (h.id || '').toLowerCase().replace(/^-+|-+$/g, '');
      if (!hNorm) continue;
      if (hNorm === normTarget || hNorm.replace(/-+/g, '-') === cleanTarget) {
        return h;
      }
    }

    // 4. Match by slugifying heading text content
    for (const h of allHeadings) {
      const textSlug = slugify(h.textContent);
      if (textSlug === cleanTarget || textSlug.replace(/-/g, '') === noHyphenTarget) {
        return h;
      }
    }

    // 5. Match by section number (e.g. "4-2", "42", "410", "4.2")
    let major = null, minor = null;
    const numDash = cleanTarget.match(/^(\d+)-(\d+)/);
    if (numDash) {
      major = numDash[1];
      minor = numDash[2];
    } else {
      const numSeq = cleanTarget.match(/^(\d)(\d+)/);
      if (numSeq) {
        major = numSeq[1];
        minor = numSeq[2];
      } else {
        const singleNum = cleanTarget.match(/^(\d+)/);
        if (singleNum) major = singleNum[1];
      }
    }

    if (major) {
      for (const h of allHeadings) {
        const text = h.textContent.trim();
        if (minor && (text.startsWith(major + '.' + minor) || text.startsWith(major + '-' + minor))) {
          return h;
        } else if (!minor && (text.startsWith(major + '.') || text.startsWith(major + ' '))) {
          return h;
        }
      }
    }

    // 6. Fuzzy substring match on heading text slug
    for (const h of allHeadings) {
      const textSlug = slugify(h.textContent);
      if (textSlug.includes(cleanTarget) || cleanTarget.includes(textSlug)) {
        return h;
      }
    }

    return null;
  };

  // Scroll to Heading (from in-page TOC link or Outline sidebar)
  window.scrollToHeading = function (headingId) {
    if (!headingId) return;
    const target = window.findHeadingElement(headingId);
    if (target) {
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      target.classList.remove('heading-target-pulse');
      void target.offsetWidth; // trigger reflow
      target.classList.add('heading-target-pulse');
    }
  };

  // Find in Page
  window.performSearch = function (query) {
    // Clear existing marks
    clearSearchHighlights();
    currentSearchMatches = [];
    currentSearchIndex = -1;

    if (!query || query.trim() === '') {
      return 0;
    }

    const container = document.getElementById('content-container');
    if (!container) return 0;

    const regex = new RegExp(`(${query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi');
    highlightTextNodes(container, regex);

    currentSearchMatches = Array.from(container.querySelectorAll('mark.search-match'));
    if (currentSearchMatches.length > 0) {
      currentSearchIndex = 0;
      updateActiveSearchMatch();
    }
    return currentSearchMatches.length;
  };

  window.nextSearchMatch = function () {
    if (currentSearchMatches.length === 0) return -1;
    currentSearchIndex = (currentSearchIndex + 1) % currentSearchMatches.length;
    updateActiveSearchMatch();
    return currentSearchIndex;
  };

  window.prevSearchMatch = function () {
    if (currentSearchMatches.length === 0) return -1;
    currentSearchIndex = (currentSearchIndex - 1 + currentSearchMatches.length) % currentSearchMatches.length;
    updateActiveSearchMatch();
    return currentSearchIndex;
  };

  function updateActiveSearchMatch() {
    currentSearchMatches.forEach((m, idx) => {
      if (idx === currentSearchIndex) {
        m.classList.add('current');
        m.scrollIntoView({ behavior: 'smooth', block: 'center' });
      } else {
        m.classList.remove('current');
      }
    });
  }

  function clearSearchHighlights() {
    const marks = document.querySelectorAll('mark.search-match');
    marks.forEach(mark => {
      const parent = mark.parentNode;
      parent.replaceChild(document.createTextNode(mark.textContent), mark);
      parent.normalize();
    });
  }

  function highlightTextNodes(node, regex) {
    if (node.nodeType === Node.TEXT_NODE) {
      const text = node.textContent;
      if (regex.test(text)) {
        const frag = document.createDocumentFragment();
        let lastIdx = 0;
        text.replace(regex, (match, p1, offset) => {
          if (offset > lastIdx) {
            frag.appendChild(document.createTextNode(text.slice(lastIdx, offset)));
          }
          const mark = document.createElement('mark');
          mark.className = 'search-match';
          mark.textContent = match;
          frag.appendChild(mark);
          lastIdx = offset + match.length;
        });
        if (lastIdx < text.length) {
          frag.appendChild(document.createTextNode(text.slice(lastIdx)));
        }
        node.parentNode.replaceChild(frag, node);
      }
    } else if (node.nodeType === Node.ELEMENT_NODE && !['SCRIPT', 'STYLE', 'PRE', 'CODE'].includes(node.nodeName)) {
      Array.from(node.childNodes).forEach(child => highlightTextNodes(child, regex));
    }
  }

  // System color scheme change listener
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    if (document.documentElement.classList.contains('theme-system')) {
      window.setTheme('system');
    }
  });

  // Prevent WebKit from navigating to dropped file URLs
  window.addEventListener('dragover', (e) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'copy';
  });

  window.addEventListener('drop', (e) => {
    e.preventDefault();
  });

})();

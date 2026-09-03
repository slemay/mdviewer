import AppKit
import WebKit

@MainActor
public enum Exporter {
    public static func printOrExportPDF(webView: WKWebView, suggestedFileName: String) {
        let printInfo = NSPrintInfo.shared
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = false
        printInfo.leftMargin = 36
        printInfo.rightMargin = 36
        printInfo.topMargin = 36
        printInfo.bottomMargin = 36

        let printOperation = webView.printOperation(with: printInfo)
        printOperation.showsPrintPanel = true
        printOperation.showsProgressPanel = true

        if let window = webView.window {
            printOperation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
        } else {
            printOperation.run()
        }
    }

    public static func savePDFDirectly(webView: WKWebView, suggestedFileName: String) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        let baseName = (suggestedFileName as NSString).deletingPathExtension
        savePanel.nameFieldStringValue = "\(baseName).pdf"
        savePanel.canCreateDirectories = true

        guard let window = webView.window else { return }

        savePanel.beginSheetModal(for: window) { response in
            if response == .OK, let targetURL = savePanel.url {
                let config = WKPDFConfiguration()
                webView.createPDF(configuration: config) { result in
                    switch result {
                    case .success(let data):
                        do {
                            try data.write(to: targetURL)
                        } catch {
                            showErrorAlert(message: "Failed to write PDF: \(error.localizedDescription)", window: window)
                        }
                    case .failure(let error):
                        showErrorAlert(message: "Failed to generate PDF: \(error.localizedDescription)", window: window)
                    }
                }
            }
        }
    }

    public static func copyRenderedHTML(webView: WKWebView) {
        webView.evaluateJavaScript("document.getElementById('content-container').innerHTML") { result, _ in
            guard let html = result as? String else { return }
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(html, forType: .html)
            pasteboard.setString(html, forType: .string)
        }
    }

    private static func showErrorAlert(message: String, window: NSWindow) {
        let alert = NSAlert()
        alert.messageText = "Export Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.beginSheetModal(for: window, completionHandler: nil)
    }
}

//
//  NoDialogBoxShareViewController.swift
//  SendIntent
//
//  https://medium.com/@damisipikuda/how-to-receive-a-shared-content-in-an-ios-application-4d5964229701
//  https://stackoverflow.com/questions/51626406/how-to-just-launch-app-from-share-extension-without-post-popup-in-swift
//  https://stackoverflow.com/a/69790810
//

import UIKit
import Social
import MobileCoreServices

open class NoDialogBoxShareViewController: UIViewController {
    
    private let CONTENTTYPE_URL = kUTTypeURL as String
    private let CONTENTTYPE_TEXT = kUTTypeText as String
    private let CONTENTTYPE_IMAGE = kUTTypeImage as String
    private let CONTENTTYPE_MOVIE = kUTTypeMovie as String
    private let CONTENTTYPE_PDF = kUTTypePDF as String

    class AttachmentURL {
        public var title: String? = ""
        public var type: String? = ""
        public var url: String? = ""
    }

    private var attachmentsURL: [AttachmentURL] = []


    open func getAppGroupId() -> String {
        return "YOUR_APP_GROUP_ID. Override this method in your ViewControler."
    }

    open func getAppUrlScheme() -> String {
        return "YOUR_APP_URL_SCHEME. Override this method in your ViewControler."
    }


    override
    public func viewDidLoad() {
        super.viewDidLoad()
        handleInputItem()
    }

    override
    public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let url = buildURL()
        openURL(url)
        attachmentsURL = []
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }


    private func handleInputItem() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
                return
        }

        for attachment in extensionItem.attachments ?? [] {
            if attachment.hasItemConformingToTypeIdentifier(CONTENTTYPE_TEXT) {
                handleInputText(itemProvider: attachment)
            } else if attachment.hasItemConformingToTypeIdentifier(CONTENTTYPE_PDF) {
                handleInputPdf(itemProvider: attachment)
            } else if attachment.hasItemConformingToTypeIdentifier(CONTENTTYPE_URL) {
                handleInputURL(itemProvider: attachment)
            } else if attachment.hasItemConformingToTypeIdentifier(CONTENTTYPE_IMAGE) {
                handleInputImage(itemProvider: attachment)
            } else if attachment.hasItemConformingToTypeIdentifier(CONTENTTYPE_MOVIE) {
                handleInputMovie(itemProvider: attachment)
            }
        }
    }

    private func handleInputText(itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: CONTENTTYPE_TEXT, options: nil, completionHandler: { (results, error) in
            if results != nil {
                let text = results as! String
                let attachmentURL: AttachmentURL = AttachmentURL()
                attachmentURL.title = text
                attachmentURL.type = "text/plain"
                self.attachmentsURL.append(attachmentURL)
            }
        })
    }

    private func handleInputURL(itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: CONTENTTYPE_URL, options: nil, completionHandler: { [self] (results, error) in
            if results != nil {
                let url = results as! URL?
                let attachmentURL : AttachmentURL = AttachmentURL()
                if url!.isFileURL {
                    attachmentURL.title = url!.lastPathComponent
                    attachmentURL.url = getSharedFileUrl(url)
                    attachmentURL.type = "application/" + url!.pathExtension.lowercased()
                } else {
                    attachmentURL.title = url!.absoluteString
                    attachmentURL.url = url!.absoluteString
                    attachmentURL.type = "text/plain"
                }
                self.attachmentsURL.append(attachmentURL)
            }
        })
    }

    private func handleInputImage(itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: CONTENTTYPE_IMAGE, options: nil, completionHandler: { [self] (results, error) in
            if results != nil {
                let url = results as! URL?
                let attachmentURL: AttachmentURL = AttachmentURL()
                attachmentURL.title = url!.lastPathComponent
                attachmentURL.url = getSharedFileUrl(url)
                attachmentURL.type = "image/*"
                self.attachmentsURL.append(attachmentURL)
            }
        })
    }


    private func handleInputPdf(itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: CONTENTTYPE_PDF, options: nil, completionHandler: { [self] (results, error) in
            if results != nil {
                let url = results as! URL?
                let attachmentURL: AttachmentURL = AttachmentURL()
                attachmentURL.title = url!.lastPathComponent
                attachmentURL.url = getSharedFileUrl(url)
                attachmentURL.type = "application/pdf"
                self.attachmentsURL.append(attachmentURL)
            }
        })
    }


    private func handleInputMovie(itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: CONTENTTYPE_MOVIE, options: nil, completionHandler: { [self] (results, error) in
            if results != nil {
                let url = results as! URL?
                let attachmentURL: AttachmentURL = AttachmentURL()
                attachmentURL.title = url!.lastPathComponent
                attachmentURL.url = getSharedFileUrl(url)
                attachmentURL.type = "video/*"
                self.attachmentsURL.append(attachmentURL)
            }
        })
    }

    fileprivate func getSharedFileUrl(_ url: URL?) -> String {
        let fileManager = FileManager.default

        let copyFileUrl = fileManager.containerURL(forSecurityApplicationGroupIdentifier: getAppGroupId())!.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)! + "/" + url!.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        try? Data(contentsOf: url!).write(to: URL(string: copyFileUrl)!)
        
        return copyFileUrl
    }
    
    private func buildURL() -> URL {
        var urlString = getAppUrlScheme() + "://"

        if (attachmentsURL.isEmpty) {
            let attachmentURL: AttachmentURL = AttachmentURL()
            urlString = urlString + "?" + buildParams(attachmentURL: attachmentURL, index: 0)
        } else {
            let attachmentURL: AttachmentURL = attachmentsURL[0]
            urlString = urlString + "?" + buildParams(attachmentURL: attachmentURL, index: 0)
            for index in 1..<attachmentsURL.count {
                let attachmentURL: AttachmentURL = attachmentsURL[index]
                urlString = urlString + "&" + buildParams(attachmentURL: attachmentURL, index: index)
            }
        }
                
        let url = URL(string: urlString)!
        return url
    }
    
    private func buildParams(attachmentURL: AttachmentURL, index: Int) -> String {
        var params = buildParamName("title", index) + "=" + buildParamValue(attachmentURL.title ?? "")
        params = params + "&" + buildParamName("type", index) + "=" + buildParamValue(attachmentURL.type ?? "")
        params = params + "&" + buildParamName("url", index) + "=" + buildParamValue(attachmentURL.url ?? "")
 
        return params
    }
    
    private func buildParamName(_ paramName: String, _ index: Int) -> String {
        let newParamName = paramName + (index>0 ? String(index) : "")
        return newParamName
    }
    
    private func buildParamValue(_ paramValue: String) -> String {
        let newParamValue = paramValue.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        return newParamValue
    }
    
    // info at: https://stackoverflow.com/a/44499222/13363449
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }
    
}

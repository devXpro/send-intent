# Send-Intent

This is a small Capacitor plugin meant to be used in Ionic applications for checking if your App was targeted as a share goal. It supports both Android and iOS. So far, it checks and returns "SEND"-intents of mimeType "text/plain", "image" or "application/octet-stream" (files).

Check out my app [mindlib - your personal mind library](https://play.google.com/store/apps/details?id=de.mindlib) to see it in action.

## Projects below Capacitor 3

For projects below Capacitor 3 please use  "send-intent": "1.1.7".

## Installation

```
npm install send-intent
npx cap sync
```

## Usage

Import & Sample call

Shared files will be received as URI-String. You can use Capacitor's [Filesystem](https://capacitorjs.com/docs/apis/filesystem) plugin to get the files content. 
The "url"-property of the SendIntent result is also used for web urls, e.g. when sharing a website via browser, so it is not necessarily a file path. Make sure to handle this
either through checking the "type"-property or by error handling.

```js
import {SendIntent} from "send-intent";

SendIntent.checkSendIntentReceived().then((result: any) => {
    if (result) {
        console.log('SendIntent received');
        console.log(JSON.stringify(result));
    }
    if (result.url) {
        let resultUrl = decodeURIComponent(result.url);
        Filesystem.readFile({path: resultUrl})
        .then((content) => {
            console.log(content.data);
        })
        .catch((err) => console.error(err));
    }
}).catch(err => console.error(err));
```

## **Android**

Configure AndroidManifest.xml

```xml
<activity
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale"
    android:name="io.ionic.starter.MainActivity"
    android:label="@string/title_activity_main"
    android:theme="@style/AppTheme.NoActionBarLaunch"
    android:launchMode="singleTask">

    <intent-filter>
          <action android:name="android.intent.action.SEND" />

          <category android:name="android.intent.category.DEFAULT" />
          <category android:name="android.intent.category.BROWSABLE" />

          <data android:mimeType="text/plain" />
          <data android:mimeType="image/*" />
          <data android:mimeType="application/octet-stream" />
    </intent-filter>
</activity>
```

If you want to use checkIntent as a listener, you need to add the following code to your MainActivity:

```java
@Override
protected void onNewIntent(Intent intent) {
    super.onNewIntent(intent);
    String action = intent.getAction();
    String type = intent.getType();
    if (Intent.ACTION_SEND.equals(action) && type != null) {
        bridge.getActivity().setIntent(intent);
        bridge.eval("window.dispatchEvent(new Event('sendIntentReceived'))", new ValueCallback<String>() {
            @Override
            public void onReceiveValue(String s) {
            }
        });
    }
}
```

And then add the listener to your client:

```js
window.addEventListener("sendIntentReceived", () => {
   Plugins.SendIntent.checkSendIntentReceived().then((result: any) => {
        if (result) {
            // ...
        }
    });
})
```

Using SendIntent as a listener can be useful if the intent doesn't trigger a rerender of your app.

## **iOS**

Create a "Share Extension" ([Creating an App extension](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionCreation.html#//apple_ref/doc/uid/TP40014214-CH5-SW1))

Code for the ShareViewController:

```swift
import UIKit
import Social
import MobileCoreServices

class ShareViewController: SLComposeServiceViewController {
    
    private var titleString: String?
    private var typeString: String?
    private var urlString: String?
    
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        print(contentText ?? "content is empty")
        return true
    }
    
    override func didSelectPost() {
        var urlString = "YOUR_APP_URL_SCHEME://?title=" + (self.titleString?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "");
        urlString = urlString + "&description=" + (self.contentText?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "");
        urlString = urlString + "&type=" + (self.typeString?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "");
        urlString = urlString + "&url=" + (self.urlString?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "");
        let url = URL(string: urlString)!
        openURL(url)
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
    fileprivate func setSharedFileUrl(_ url: URL?) {
        let fileManager = FileManager.default
        
        let copyFileUrl = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "YOUR_APP_GROUP_ID")!.absoluteString + "/" + url!.lastPathComponent
        
        try? Data(contentsOf: url!).write(to: URL(string: copyFileUrl)!)
        
        self.urlString = copyFileUrl
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let extensionItem = extensionContext?.inputItems[0] as! NSExtensionItem
        let contentTypeURL = kUTTypeURL as String
        let contentTypeText = kUTTypeText as String
        let contentTypeImage = kUTTypeImage as String
        
        for attachment in extensionItem.attachments as! [NSItemProvider] {
            
            attachment.loadItem(forTypeIdentifier: contentTypeURL, options: nil, completionHandler: { [self] (results, error) in
                if results != nil {
                    let url = results as! URL?
                    if url!.isFileURL {
                        self.titleString = url!.lastPathComponent
                        self.typeString = "application/" + url!.pathExtension
                        setSharedFileUrl(url)
                    } else {
                        self.titleString = url!.absoluteString
                        self.urlString = url!.absoluteString
                        self.typeString = "text/plain"
                    }
                    
                }
            })
            
            attachment.loadItem(forTypeIdentifier: contentTypeText, options: nil, completionHandler: { (results, error) in
                if results != nil {
                    let text = results as! String
                    self.titleString = text
                    _ = self.isContentValid()
                    self.typeString = "text/plain"
                }
            })
            
            attachment.loadItem(forTypeIdentifier: contentTypeImage, options: nil, completionHandler: { [self] (results, error) in
                if results != nil {
                    let url = results as! URL?
                    self.titleString = url!.lastPathComponent
                    self.typeString = "image/" + url!.pathExtension
                    setSharedFileUrl(url)
                }
            })
            
        }
    }
    
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

```

The share extension is like a little standalone program, so to get to your app the extension has to make an openURL call. In order to make your app reachable by a URL, you have to define a URL scheme ([Register Your URL Scheme](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app)). The code above calls a URL scheme named "YOUR_APP_URL_SCHEME" (first line in "didSelectPost"), so just replace this with your scheme.
To allow sharing of files between the extension and your main app, you need to [create an app group](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups) which is checked for both your extension and main app. Replace "YOUR_APP_GROUP_ID" in "setSharedFileUrl()" with your app groups name.

Finally, in your AppDelegate.swift, override the following function like this:

```swift
import SendIntent
import Capacitor

// ...

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // ...

    let store = ShareStore.store

    // ...

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
            
        var success = true
        if CAPBridge.handleOpenUrl(url, options) {
            success = ApplicationDelegateProxy.shared.application(app, open: url, options: options)
        }
        
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              let params = components.queryItems else {
                  return false
              }
        store.title = params.first(where: { $0.name == "title" })?.value as! String
        store.description = params.first(where: { $0.name == "description" })?.value as! String
        store.type = params.first(where: { $0.name == "type" })?.value as! String
        store.url = params.first(where: { $0.name == "url" })?.value as! String
        store.processed = false
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("triggerSendIntent"), object: nil )
        
        return success
    }

    // ...

}
```

This is the function started when an application is open by URL.

Also, make sure you use SendIntent as a listener. Otherwise you will miss the event fired in the plugin:

```js
window.addEventListener("sendIntentReceived", () => {
    Plugins.SendIntent.checkSendIntentReceived().then((result: any) => {
        if (result) {
            // ...
        }
    });
})
```

## Another approach to ShareViewController without the default dialog box (extending from UIViewController) and support to multiple files
Code for the ShareViewController:

```swift
//
//  ShareViewController.swift
//  ShareWithMetricool
//
//  https://github.com/carsten-klaffke/send-intent
//  https://medium.com/@damisipikuda/how-to-receive-a-shared-content-in-an-ios-application-4d5964229701
//  https://stackoverflow.com/questions/51626406/how-to-just-launch-app-from-share-extension-without-post-popup-in-swift
//  https://stackoverflow.com/a/69790810
//

import UIKit
import Social
import MobileCoreServices

class ShareViewController: UIViewController {
    
    private let APP_GROUP_ID = "YOUR_APP_GROUP_ID"
    private let APP_URL_SCHEME = "YOUR_APP_URL_SCHEME"
    
    private let CONTENTTYPE_URL = kUTTypeURL as String
    private let CONTENTTYPE_TEXT = kUTTypeText as String
    private let CONTENTTYPE_IMAGE = kUTTypeImage as String
    private let CONTENTTYPE_MOVIE = kUTTypeMovie as String

    class AttachmentURL {
        public var title: String? = ""
        public var type: String? = ""
        public var url: String? = ""
    }
    
    private var attachmentsURL: [AttachmentURL] = []
    
    override
    func viewDidLoad() {
        super.viewDidLoad()
        handleInputItem()
    }
    
    override
    func viewDidAppear(_ animated: Bool) {
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
        
        let copyFileUrl = fileManager.containerURL(forSecurityApplicationGroupIdentifier: APP_GROUP_ID)!.absoluteString + "/" + url!.lastPathComponent
        
        try? Data(contentsOf: url!).write(to: URL(string: copyFileUrl)!)
        
        return copyFileUrl
    }
    
    private func buildURL() -> URL {
        var urlString = APP_URL_SCHEME + "://"

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
```

And the AppDelegate.swift to support multiple files:

```swift
// ...

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // ...

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var success = false
    
        // ...
      
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
        let params = components.queryItems else {
            return success
        }
        
        // fill in store object
        store.title = params.first(where: { $0.name == "title" })?.value ?? ""
        //store.description = params.first(where: { $0.name == "description" })?.value as! String
        store.type = params.first(where: { $0.name == "type" })?.value ?? ""
        store.url = params.first(where: { $0.name == "url" })?.value ?? ""
        
        // fill additionalItems in store
        var hasMoreItems : Bool = true
        var index = 1
        while (hasMoreItems) {
            let item : ShareStore = ShareStore()
            
            if let param = params.first(where: { $0.name == "title" + String(index)}) {
                item.title = param.value ?? ""
                
                if let param = params.first(where: { $0.name == "type" + String(index)}) {
                    item.type = param.value ?? ""
                    
                    if let param = params.first(where: { $0.name == "url" + String(index)}) {
                        item.url = param.value ?? ""
                        index+=1
                        store.additionalItems.append(item)
                        continue
                    }
                }
            }
            hasMoreItems = false
        }
          
        store.processed = false
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("triggerSendIntent"), object: nil )
        
        return success
    }

    // ...
}
```

## Donation

If you want to support my work, you can donate me on bitcoin:bc1q60ntnlz4wqfup3yg3hyqmzfkuraf8clmvupqvs

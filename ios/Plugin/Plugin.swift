import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitor.ionicframework.com/docs/plugins/ios
 */
@objc(SendIntent)
public class SendIntent: CAPPlugin {
    
    let store = ShareStore.store

    @objc func checkSendIntentReceived(_ call: CAPPluginCall) {
        if !store.processed {
            let data = buildData()
            call.resolve(data)
            store.clear()
            store.processed = true
        } else {
            call.reject("No processing needed.")
        }
    }
    
    private func buildData() -> [String: Any] {
        var data: [String: Any] = [
            "title": store.title,
            "description": store.description,
            "type": store.type,
            "url": store.url
        ]
        
        if (!store.additionalItems.isEmpty) {
            var additionalItems = [[String: Any]]()
            for item in store.additionalItems {
                let itemAsData: [String: Any] = [
                    "title": item.title,
                    "description": item.description,
                    "type": item.type,
                    "url": item.url
                ]
                additionalItems.append(itemAsData)
            }
            
            data["additionalItems"] = additionalItems
        }
        
        return data
    }

    public override func load() {
        let nc = NotificationCenter.default
            nc.addObserver(self, selector: #selector(eval), name: Notification.Name("triggerSendIntent"), object: nil)
    }

    @objc open func eval(){
        self.bridge?.eval(js: "window.dispatchEvent(new Event('sendIntentReceived'))");
    }

}

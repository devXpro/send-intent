//
//  SendIntentAppDelegateHelper.swift
//  SendIntent
//

public class SendIntentAppDelegateHelper {

    public static func PostNotification(url: URL) -> Bool {
        let store = ShareStore.store

        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
        let params = components.queryItems else {
            return false
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
        
        return true
    }

}

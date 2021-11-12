import Foundation

public final class ShareStore {

    public static let store = ShareStore()
    
    public init() {}

    public var title: String = ""
    public var description: String = ""
    public var type: String = ""
    public var url: String = ""
    public var additionalItems: Array<ShareStore> = Array()
    public var processed: Bool = false
    
    public func clear() {
        title = ""
        description = ""
        type = ""
        url = ""
        processed = false
        additionalItems = Array()
    }
}

import Foundation

public struct BorshEncoder {
    public func encode<T>(_ value: T) throws -> Data where T: BorshSerializable {
        var writer = Data()
        try value.serialize(to: &writer)
        return writer
    }
}

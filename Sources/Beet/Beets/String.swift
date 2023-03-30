import Foundation

/**
 * De/Serializes a UTF8 string of a particular size.
 *
 * @param stringByteLength the number of bytes of the string
 *
 * @category beet/collection
 */
public class FixedSizeUtf8String: ElementCollectionFixedSizeBeet {
    public var length: UInt32
    let stringByteLength: UInt
    public let byteSize: UInt
    public var elementByteSize: UInt = 1
    public var lenPrefixByteSize: UInt = 4
    public let description: String

    public init(stringByteLength: UInt) {
        self.length = UInt32(stringByteLength)
        self.stringByteLength = stringByteLength
        self.byteSize = 4 + stringByteLength
        self.description = "Utf8String(4 + \(stringByteLength)}"
    }

    public func write<T>(buf: inout Data, offset: Int, value: T) throws {
        var advanced = buf
        let string = value as! String
        let data = Data(string.utf8)
        if !(data.count == stringByteLength) { throw BeetError.assert("\(string) has invalid byte size") }
        u32().write(buf: &advanced, offset: offset, value: UInt32(data.count))
        advanced.replaceSubrange((offset+4)..<(offset+4+data.count), with: data)
        buf = advanced
    }

    public func read<T>(buf: Data, offset: Int) throws -> T {
        let size: UInt32 = u32().read(buf: buf, offset: offset)
        if !(size == stringByteLength) { throw BeetError.assert("invalid byte size") }
        let stringSlice = buf.bytes[(offset+4)..<(offset+4+Int(stringByteLength))]
        return String(data: Data(stringSlice), encoding: .utf8) as! T
    }
}

/**
 * De/Serializes a UTF8 string of any size.
 *
 * @category beet/collection
 */
public class Utf8String: FixableBeet {
    public init(){}
    public func toFixedFromData(buf: Data, offset: Int) -> FixedSizeBeet {
        let len: UInt32 = u32().read(buf: buf, offset: offset)
        debugPrint("\(self.description)[\(len)]")
        return .init(value: .collection(FixedSizeUtf8String(stringByteLength: UInt(len))))
    }

    public func toFixedFromValue(val: Any) -> FixedSizeBeet {
        let value = val as! String
        let data = Data(value.utf8)
        let len = data.bytes.count
        debugPrint("\(self.description)[\(len)]")
        return .init(value: .collection(FixedSizeUtf8String(stringByteLength: UInt(len))))
    }

    public var description: String = "Utf8String"
}

public enum StringTypeMapKey: String {
    case string
    case fixedSizeString
}

public typealias StringTypeMap = (StringTypeMapKey, SupportedTypeDefinition)

public let stringTypeMap: [StringTypeMap] = [
    (StringTypeMapKey.string, SupportedTypeDefinition(beet: "Utf8String()", isFixable: true, sourcePack: BEET_PACKAGE, swift: "String", arg: BeetTypeArg.len)),
    (StringTypeMapKey.fixedSizeString, SupportedTypeDefinition(beet: "FixedSizeBeet(value: .collection(FixedSizeUtf8String(stringByteLength: {len})))))", isFixable: false, sourcePack: BEET_PACKAGE, swift: "String", arg: BeetTypeArg.len))
]

import Foundation

public typealias Args = [AnyHashable: Any]
public class BeetStruct<Class>: ScalarFixedSizeBeet {
    let TYPE: String = "BeetStruct"
    let fields: [FixedBeetField]
    public let description: String
    public var byteSize: UInt { getByteSize() }

    let construct: (_ args: Args) -> Class

    public init(fields: [FixedBeetField],
         construct: @escaping (_ args: Args) -> Class,
         description: String = "BeetStruct"
    ) {
        self.fields = fields
        self.construct = construct
        self.description = description
    }

    private func getByteSize() -> UInt {
        var acc: UInt = 0
        for field in self.fields {
            switch field.beet.value {
            case .scalar(let type):
                acc = acc + type.byteSize
            case .collection(let type):
                acc = acc + type.byteSize
            }
        }
        return acc
    }

    /**
     * Along with `read` this allows structs to be treated as {@link Beet}s and
     * thus supports composing/nesting them the same way.
     * @private
     */
    public func write<T>(buf: inout Data, offset: Int, value: T) throws {
        let (innerBuf, innerOffset) = try self.serialize(instance: value as! Class)
        var advanced = buf
        let data = innerBuf.bytes[0..<innerOffset]
        advanced.replaceSubrange(offset..<offset+data.count, with: data)
        buf = advanced
    }

    /**
     * Along with `write` this allows structs to be treated as {@link Beet}s and
     * thus supports composing/nesting them the same way.
     * @private
     */
    public func read<T>(buf: Data, offset: Int) throws -> T {
        let k: (Class, Int) = try self.deserialize(buffer: buf, offset: offset)
        return k.0 as! T
    }

    /**
     * Deserializes an instance of the Class from the provided buffer starting to
     * read at the provided offset.
     *
     * @returns `[instance of Class, offset into buffer after deserialization completed]`
     */
    public func deserialize(buffer: Data, offset: Int = 0) throws -> (Class, Int) {
        let reader = BeetReader(buffer: buffer, offset: offset)
        let args = try reader.readStruct(fields: self.fields) as Args
        return (self.construct(args), reader.offset())
    }

    /**
     * Serializes the provided instance into a new {@link Buffer}
     *
     * @param instance of the struct to serialize
     * @param byteSize allows to override the size fo the created Buffer and
     * defaults to the size of the struct to serialize
     */
    public func serialize(instance: Class, byteSize: Int?=nil) throws -> (Data, Int) {
        let writer = BeetWriter(byteSize: byteSize ?? Int(self.byteSize))
        try writer.writeStruct(instance: instance, fields: self.fields)
        return (writer.buffer(), writer.offset())
    }

    public func type() -> String {
        return TYPE
    }
}

public class BeetArgsStruct: BeetStruct<Args> {
    public init(fields: [FixedBeetField],
         description: String = "BeetArgsStruct"
    ) {
        super.init(fields: fields) { args in
            args
        }
    }
}

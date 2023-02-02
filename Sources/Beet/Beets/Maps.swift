import Foundation

public struct fixedSizeMap: ElementCollectionFixedSizeBeet {
   
    public let keyElement: Beet
    public let valElement: Beet
    public let fixedElements: [AnyHashable: (FixedSizeBeet, FixedSizeBeet)]
    public let len: UInt32
    
    public var description: String
    public var length: UInt32
    public var lenPrefixByteSize: UInt
    public var byteSize: UInt
    public var elementByteSize: UInt
    
    private var keyElementFixed: Bool {
        return isFixedSizeBeet(x: keyElement)
    }
    
    private var valElementFixed: Bool {
        return isFixedSizeBeet(x: valElement)
    }
    
    public init(
        keyElement: Beet,
        valElement: Beet,
        fixedElements: [AnyHashable : (FixedSizeBeet, FixedSizeBeet)],
         len: UInt32
    ) {
        self.keyElement = keyElement
        self.valElement = valElement
        self.fixedElements = fixedElements
        self.len = len
        
        self.description =  "Map<\(keyElement.description), \(valElement.description)>"
        self.length = self.len
        self.lenPrefixByteSize = 4
        
        self.byteSize = 0
        self.elementByteSize = 0
        
        let size = determineSizes()
        self.byteSize = size.byteSize
        self.elementByteSize = size.elementByteSize
    }
    
    public func determineSizes() -> (elementByteSize: UInt, byteSize: UInt) {
        if case let .fixedBeet(fixedKeyElement) = keyElement,
           case let .fixedBeet(fixedValElement) = valElement {
            let elementByteSize = fixedKeyElement.byteSize + fixedValElement.byteSize
            return (elementByteSize, 4 + UInt(len) * elementByteSize)
            
        } else if case let .fixedBeet(fixedKeyElement) = keyElement {
            var valsByteSize: UInt = 0
            for (_, v) in fixedElements.values {
                valsByteSize += v.byteSize
            }
            
            // If any element has a dynamic size all we can do here is take an average
            let elementByteSize = fixedKeyElement.byteSize + UInt(Double(valsByteSize) / Double(len).rounded(.up)  )
            return (elementByteSize, 4 + fixedKeyElement.byteSize * UInt(len) + valsByteSize)
        } else if case let .fixedBeet(fixedValElement) = valElement {
            var keysByteSize: UInt = 0
            for (k,_) in fixedElements.values {
                keysByteSize += k.byteSize
            }
            let elementByteSize = UInt(Double(keysByteSize) / Double(len).rounded(.up)) + fixedValElement.byteSize
            return (elementByteSize, 4 + keysByteSize + fixedValElement.byteSize * UInt(len))
        } else {
            var keysByteSize: UInt = 0
            var valsByteSize: UInt = 0
            for (k,v) in fixedElements.values {
                keysByteSize += k.byteSize
                valsByteSize += v.byteSize
            }
            
            let elementByteSize = UInt((Double(keysByteSize) / Double(len) + Double(valsByteSize) / Double(len)).rounded(.up))
            return (elementByteSize, 4 + keysByteSize + valsByteSize)
        }
    }
    

    
    public func write<T>(buf: inout Data, offset: Int, value: T) {
        let map = value as! [AnyHashable: Any]
        
        // Write the values first and then the size as it comes clear while we do the former
        var cursor = offset + 4
        var size: UInt32 = 0
                
        map.forEach { (k,v) in
            var fixedKey: FixedSizeBeet? = nil
            if case let .fixedBeet(fixedKeyElement) = keyElement {
                fixedKey = fixedKeyElement
            }
            
            var fixedVal: FixedSizeBeet? = nil
            if case let .fixedBeet(x: fixedValElement) = valElement {
                fixedVal = fixedValElement
            }
            
            if fixedKey == nil || fixedVal == nil {
                // When we write the value we know the key and an just pull the
                // matching fixed beet for key/val from the provided map which is
                // faster than fixing it by value
                guard let els = fixedElements[k] else {
                    fatalError("Should be able to find beet els for \(k), but could not")
                }
                fixedKey = els.0
                fixedVal = els.1
                
            }
            
            fixedKey!.write(buf: &buf, offset: cursor, value: k)
            cursor += Int(fixedKey!.byteSize)

            fixedVal!.write(buf: &buf, offset: cursor, value: v)
            cursor += Int(fixedVal!.byteSize)
            size += 1
        }
        
        u32().write(buf: &buf, offset: offset, value: size)
        if len != size { fatalError("Expected map to have size \(len), but has \(size)") }
    }
    
    public func read<T>(buf: Data, offset: Int) -> T {
        let size: UInt32 = u32().read(buf: buf, offset: offset)
        if len != size { fatalError("Expected map to have size \(len), but has \(size)") }
        var cursor = offset + 4
        
        var map: [AnyHashable: Any] = [:]
        
        for _ in 0..<size{
            // When we read the value from a buffer we don't know the key we're
            // reading yet and thus cannot use the provided map of fixed
            // de/serializers.
            // Therefore we obtain it by fixing it by data instead.
            let fixedKey: FixedSizeBeet
            switch keyElement{
            case .fixedBeet(let fixed):
                fixedKey = fixed
            case .fixableBeat(let fixable):
                fixedKey = fixable.toFixedFromData(buf: buf, offset: cursor)
            }
            
            let k: AnyHashable = fixedKey.read(buf: buf, offset: cursor)
            cursor += Int(fixedKey.byteSize)
            
            let fixedVal: FixedSizeBeet
            switch valElement{
            case .fixedBeet(let fixed):
                fixedVal = fixed
            case .fixableBeat(let fixable):
                fixedVal = fixable.toFixedFromData(buf: buf, offset: cursor)
            }
            
            let v: Any = fixedVal.read(buf: buf, offset: cursor)
            cursor += Int(fixedVal.byteSize)
            
            map[k] = v
        }

        return map as! T
    }
}

public struct map: FixableBeet {
    public let keyElement: Beet
    public let valElement: Beet
    
    private var keyIsFixed: Bool {
        return isFixedSizeBeet(x: keyElement)
    }
    
    private var valIsFixed: Bool {
        return isFixedSizeBeet(x: valElement)
    }
    
    public func toFixedFromData(buf: Data, offset: Int) -> FixedSizeBeet {
        let len: UInt32 = u32().read(buf: buf, offset: offset)
        var cursor = offset + 4
        // Shortcut for the case that both key and value are fixed size beets
        if (keyIsFixed && valIsFixed) {
            return FixedSizeBeet(
                value: FixedSizeBeetType.collection(
                    fixedSizeMap(keyElement: keyElement, valElement: valElement, fixedElements: [:], len: len)
                )
            )
        }
        // If either key or val are not fixed size beets we need to determine the
        // fixed versions and add them to a map by key
        var fixedBeets: [AnyHashable: (FixedSizeBeet, FixedSizeBeet)] = [:]
        for _ in 0..<len {
            let keyFixed: FixedSizeBeet
            switch keyElement {
            case .fixedBeet(let fixed):
                keyFixed = fixed
            case .fixableBeat(let fixable):
                keyFixed = fixable.toFixedFromData(buf: buf, offset: cursor)
            }
            let key: AnyHashable = keyFixed.read(buf: buf, offset: cursor)
            cursor += Int(keyFixed.byteSize)
            
            let valFixed: FixedSizeBeet
            switch valElement {
            case .fixedBeet(let fixed):
                valFixed = fixed
            case .fixableBeat(let fixable):
                valFixed = fixable.toFixedFromData(buf: buf, offset: cursor)
            }
            
            fixedBeets[key] = (keyFixed, valFixed)
            cursor += Int(valFixed.byteSize)
        }
        return FixedSizeBeet(
            value: FixedSizeBeetType.collection(
                fixedSizeMap(keyElement: keyElement, valElement: valElement, fixedElements: fixedBeets, len: len)
            )
        )
    }
    
    public func toFixedFromValue(val: Any) -> FixedSizeBeet {
        let mapVal = val as! [AnyHashable: Any]
        let len = mapVal.count
        if (keyIsFixed && valIsFixed) {
            return FixedSizeBeet(
                value: FixedSizeBeetType.collection(
                    fixedSizeMap(
                        keyElement: keyElement, valElement: valElement, fixedElements: [:], len: UInt32(len)
                    )
                )
            )
        }
        var fixedBeets: [AnyHashable: (FixedSizeBeet, FixedSizeBeet)] = [:]
        mapVal.forEach { (k, v) in
            let keyFixed: FixedSizeBeet
            switch keyElement {
            case .fixedBeet(let fixed):
                keyFixed = fixed
            case .fixableBeat(let fixable):
                keyFixed = fixable.toFixedFromValue(val: k)
            }
            
            let valFixed: FixedSizeBeet
            switch valElement {
            case .fixedBeet(let fixed):
                valFixed = fixed
            case .fixableBeat(let fixable):
                valFixed = fixable.toFixedFromValue(val: v)
            }
            
            fixedBeets[k] = (keyFixed, valFixed)
        }
        return FixedSizeBeet(
            value: FixedSizeBeetType.collection(
                fixedSizeMap(keyElement: keyElement, valElement: valElement, fixedElements: fixedBeets, len: UInt32(len))
            )
        )
    }
    
    public var description: String {
        "FixableMap<\(keyElement.description), $\(valElement.description)>"
    }
}

public enum MapsTypeMapKey: String {
    case map
}

public typealias MapsTypeMap = (MapsTypeMapKey, SupportedTypeDefinition)

public let mapsTypeMap: [MapsTypeMap] = [
    (MapsTypeMapKey.map, SupportedTypeDefinition(beet: "map(keyElement: {{innerK}}, valElement: {{innerV}})", isFixable: true, sourcePack: BEET_PACKAGE, swift: "Dictionary"))
]

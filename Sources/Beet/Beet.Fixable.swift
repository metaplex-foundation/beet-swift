import Foundation

func fixBeetFromData(beet: Beet, buf: Data, offset: Int) throws -> FixedSizeBeet {
    switch beet {
    case .fixedBeet(let fixedSizeBeet):
        return fixedSizeBeet
    case .fixableBeat(let fixableBeet):
        return try fixableBeet.toFixedFromData(buf: buf, offset: offset)
    }
}

func fixBeetFromValue<V>(beet: Beet, val: V) throws -> FixedSizeBeet {
    switch beet {
    case .fixedBeet(let fixedSizeBeet):
        return fixedSizeBeet
    case .fixableBeat(let fixableBeet):
        return try fixableBeet.toFixedFromValue(val: val)
    }
}

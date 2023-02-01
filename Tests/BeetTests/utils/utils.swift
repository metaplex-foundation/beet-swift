import Foundation
import XCTest
@testable import Beet

func checkFixedSerialize<T>(
  fixedBeet: FixedSizeBeet,
  value: T,
  data: Data,
  description: String
) {
    var buf = Data(count: Int(fixedBeet.byteSize))
    fixedBeet.write(buf: &buf, offset: 0, value: value)
    XCTAssertEqual(data, buf)
}

func checkFixedDeserialize<T: Equatable>(
  fixedBeet: FixedSizeBeet,
  value: T,
  data: Data,
  description: String? = nil
) {
    let actual: T = fixedBeet.read(buf: data, offset: 0)
    XCTAssertEqual(actual, value)
}

func checkFixedSerialization<T: Equatable>(
  fixedBeet: FixedSizeBeet,
  value: T,
  data: Data,
  description: String
) {
    checkFixedSerialize(fixedBeet: fixedBeet, value: value, data: data, description: description)
    checkFixedDeserialize(fixedBeet: fixedBeet, value: value, data: data, description: description)
}

func checkFixableFromDataSerialization<T: Equatable>(
  fixabledBeet: FixableBeet,
  value: T,
  data: Data,
  description: String
) {
    let fixedBeet = fixabledBeet.toFixedFromData(buf: data, offset: 0)
    checkFixedSerialize(fixedBeet: fixedBeet, value: value, data: data, description: description)
    checkFixedDeserialize(fixedBeet: fixedBeet, value: value, data: data, description: description)
}

func checkFixableFromValueSerialization<T: Equatable>(
  fixabledBeet: FixableBeet,
  value: T,
  data: Data,
  description: String
) {
    let fixedBeet = fixabledBeet.toFixedFromValue(val: value)
    checkFixedSerialize(fixedBeet: fixedBeet, value: value, data: data, description: description)
    checkFixedDeserialize(fixedBeet: fixedBeet, value: value, data: data, description: description)
}

// -----------------
// Maps
// -----------------
func checkMapSerialize<K: Hashable, V>(
    m: [K: V],
    mapBeet: FixedSizeBeet,
    keyBeet: Beet,
    valBeet: Beet
){
    var serializedMap = Data(count: Int(mapBeet.byteSize))
    mapBeet.write(buf: &serializedMap, offset: 0, value: m)
    serializedMapIncludesKeyVals(serializedMap: serializedMap, m: m, keyBeet: keyBeet, valBeet: valBeet)
}

/**
 * Verifies that each keyval of the provided map value {@link m} is contained in
 * the {@link serializedMap}.
 * Map key/vals aren't ordered and thus it is unknown how they are written to
 * the buffer when serialized.
 * Therefore we cannot compare the serialized buffers directly but have to look
 * each key/val up one by one.
 */
func serializedMapIncludesKeyVals<K: Hashable, V>(
  serializedMap: Data,
  m: [K: V],
  keyBeet: Beet,
  valBeet: Beet
){
    for (k,v) in m {
        let fixedKey = fixFromValIfNeeded(beet: keyBeet, v: k)
        let fixedVal = fixFromValIfNeeded(beet: valBeet, v: v)
        
        var keyBuf = Data(count: Int(fixedKey.byteSize))
        var valBuf = Data(count: Int(fixedVal.byteSize))
        
        fixedKey.write(buf: &keyBuf, offset: 0, value: k)
        fixedVal.write(buf: &valBuf, offset: 0, value: v)
        
        XCTAssert(bufferIncludes(buf: serializedMap, snippet: keyBuf + valBuf), "serialized map includes \(k) \(v)")
    }
}


func fixFromValIfNeeded<V>(beet: Beet, v: V) -> FixedSizeBeet {
    switch beet{
    case .fixedBeet(let fixed):
        return fixed
    case .fixableBeat(let fixable):
        return fixable.toFixedFromValue(val: v)
    }
}

func bufferIncludes(buf: Data, snippet: Data) -> Bool {
  return buf.hexString.contains(snippet.hexString)
}

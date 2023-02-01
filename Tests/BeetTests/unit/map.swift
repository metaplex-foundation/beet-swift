import Foundation
import XCTest
@testable import Beet

final class mapTests: XCTestCase {
    func testCompatMapsTopLevelHMapU8U8() {
        let beet = map(keyElement: .fixedBeet(.init(value: .scalar(u8()))),
                       valElement: .fixedBeet(.init(value: .scalar(u8())))
        )
        
        let fixtures = stubbedResponse("maps")
        for fixture in fixtures["hash_map_u8_u8s"]! {
            print(fixture)
            
            if  case let .dict(dictionary) = fixture.value{
                
                var m: [UInt8: UInt8] = [:]
                for (key, value) in dictionary {
                    let k = UInt8(key)!
                    let v  = UInt8(value as! Int)
                    m[k] = v
                }
                let data = Data(fixture.data)
                
                let fixedBeetFromData = beet.toFixedFromData(buf: data, offset: 0)
                checkFixedDeserialize(fixedBeet: fixedBeetFromData, value: m, data: data, description: "")
                checkMapSerialize(m: m, mapBeet: fixedBeetFromData, keyBeet: .fixedBeet(.init(value: .scalar(u8()))), valBeet: .fixedBeet(.init(value: .scalar(u8()))))
                
                let fixedBeetFromValue = beet.toFixedFromValue(val: m)
                checkFixedDeserialize(fixedBeet: fixedBeetFromValue, value: m, data: data, description: "")
                checkMapSerialize(m: m, mapBeet: fixedBeetFromValue, keyBeet: .fixedBeet(.init(value: .scalar(u8()))), valBeet: .fixedBeet(.init(value: .scalar(u8()))))
            }
            
        }
    }
    
    func testCompatMapsTopLevelBTreeMapU8U8(){
        let beet = map(keyElement: .fixedBeet(.init(value: .scalar(u8()))),
                       valElement: .fixedBeet(.init(value: .scalar(u8())))
        )
        let fixtures = stubbedResponse("maps")
        for fixture in fixtures["btree_map_u8_u8s"]! {
            
            if  case let .dict(dictionary) = fixture.value{
                var m: [UInt8: UInt8] = [:]
                for (key, value) in dictionary {
                    let k = UInt8(key)!
                    let v  = UInt8(value as! Int)
                    m[k] = v
                }
                let data = Data(fixture.data)
                
                let fixedBeetFromData = beet.toFixedFromData(buf: data, offset: 0)
                checkFixedDeserialize(fixedBeet: fixedBeetFromData, value: m, data: data, description: "")
                checkMapSerialize(m: m, mapBeet: fixedBeetFromData, keyBeet: .fixedBeet(.init(value: .scalar(u8()))), valBeet: .fixedBeet(.init(value: .scalar(u8()))))
                
                let fixedBeetFromValue = beet.toFixedFromValue(val: m)
                checkFixedDeserialize(fixedBeet: fixedBeetFromValue, value: m, data: data, description: "")
                checkMapSerialize(m: m, mapBeet: fixedBeetFromValue, keyBeet: .fixedBeet(.init(value: .scalar(u8()))), valBeet: .fixedBeet(.init(value: .scalar(u8()))))
            }
        }
    }
    func testCompatMapsTopLevelHashMapStringI32(){
        let beet = map(keyElement: .fixableBeat(Utf8String()),
                       valElement: .fixedBeet(.init(value: .scalar(i32())))
        )
        let fixtures = stubbedResponse("maps")
        for fixture in fixtures["hash_map_string_i32s"]! {
            if  case let .dict(dictionary) = fixture.value{
                var m: [String: Int32] = [:]
                for (key, value) in dictionary {
                    let k = key
                    let v  = Int32(value as! Int)
                    m[k] = v
                }
                let data = Data(fixture.data)
                
                let fixedBeetFromData = beet.toFixedFromData(buf: data, offset: 0)
                checkFixedDeserialize(fixedBeet: fixedBeetFromData, value: m, data: data)
                checkMapSerialize(m: m, mapBeet: fixedBeetFromData, keyBeet: .fixableBeat(Utf8String()), valBeet: .fixedBeet(.init(value: .scalar(i32()))))
                
                let fixedBeetFromValue = beet.toFixedFromValue(val: m)
                checkFixedDeserialize(fixedBeet: fixedBeetFromValue, value: m, data: data)
                checkMapSerialize(m: m, mapBeet: fixedBeetFromValue, keyBeet: .fixableBeat(Utf8String()), valBeet: .fixedBeet(.init(value: .scalar(i32()))))
            }
        }
    }
    
    func testCompatMapsTopLevelHashMapStringArrayI8(){
        let beet = map(keyElement: .fixableBeat(Utf8String()),
                       valElement: .fixableBeat(array(element: .fixedBeet(.init(value: .scalar(i8())))))
        )
        let fixtures = stubbedResponse("maps")
        for fixture in fixtures["hash_map_string_vec_i8s"]! {
            if  case let .dict(dictionary) = fixture.value{
                var m: [String: [Int8]] = [:]
                for (key, value) in dictionary {
                    let k = key
                    let v  = (value as! [Int]).map{ Int8($0) }
                    m[k] = v
                }
                let data = Data(fixture.data)
                
                let fixedBeetFromData = beet.toFixedFromData(buf: data, offset: 0)
                checkFixedDeserialize(fixedBeet: fixedBeetFromData, value: m, data: data)
                checkMapSerialize(m: m, mapBeet: fixedBeetFromData, keyBeet: .fixableBeat(Utf8String()), valBeet: .fixableBeat(array(element: .fixedBeet(.init(value: .scalar(i8()))))))
                
                let fixedBeetFromValue = beet.toFixedFromValue(val: m)
                checkFixedDeserialize(fixedBeet: fixedBeetFromValue, value: m, data: data)
                checkMapSerialize(m: m, mapBeet: fixedBeetFromValue, keyBeet: .fixableBeat(Utf8String()), valBeet: .fixableBeat(array(element: .fixedBeet(.init(value: .scalar(i8()))))))
            }
        }
    }
    
    func testCompatMapsTopLevelVecHashMapStringI64(){
        // NOTE: this checks deserialization only as it turned out complex enough
        // already to set up this test
        let beet = array(element: .fixableBeat(
                            map(keyElement: .fixableBeat(Utf8String()),
                                valElement: .fixedBeet(.init(value: .scalar(i64())))
                            )
                        )
                    )
        
        let fixtures = stubbedResponse("maps")
        for fixture in fixtures["vec_hash_map_string_i64s"]! {
            if  case let .arrayValueType(array) = fixture.value{
                let arrayDict = array.map { $0 as! [String: Int] }
                print(arrayDict)
                var m: [[String: Int64]] = []
                arrayDict.forEach { dictionary in
                    var d: [String: Int64] = [:]
                    for (key, value) in dictionary {
                        let k = key
                        let v  = Int64(value)
                        d[k] = v
                    }
                    m.append(d)
                }
                
                let data = Data(fixture.data)
                
                let fixedBeetFromData = beet.toFixedFromData(buf: data, offset: 0)
                // Serialization
                let actual: [[String: Int64]] = fixedBeetFromData.read(buf: data, offset: 0)
                
                XCTAssert(m == actual)
                
                // Deserialization
                var serialized = Data(count: Int(fixedBeetFromData.byteSize))
                fixedBeetFromData.write(buf: &serialized, offset: 0, value: actual)

            }
        }
    }
}

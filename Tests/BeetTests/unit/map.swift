import Foundation
import XCTest
@testable import Beet

final class mapTests: XCTestCase {
    func testCompatMapsTopLevelHMapU8U8() {
        let beet = map<u8, u8>(keyElement: u8(), valElement: u8())
    }
}

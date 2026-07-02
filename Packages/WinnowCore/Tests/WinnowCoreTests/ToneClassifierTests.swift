import Foundation
import Testing
@testable import WinnowCore

@Suite("ToneClassifier")
struct ToneClassifierTests {

    @Test("a personal note classifies as personal")
    func personalNote() async {
        guard await ToneClassifier.shared.isAvailable else { return }
        let tone = await ToneClassifier.shared.tone(
            subject: "Lunch Thursday?",
            preview: "Fancy trying the new ramen place near the studio? My shout."
        )
        #expect(tone == .personal)
    }

    @Test("a shipping notification does not classify as personal")
    func shipmentNotPersonal() async {
        guard await ToneClassifier.shared.isAvailable else { return }
        let tone = await ToneClassifier.shared.tone(
            subject: "Order 8213140156387452: order shipped",
            preview: "Your order has shipped, and you can track its every move by clicking below."
        )
        #expect(tone != .personal)
    }

    @Test("a product update does not classify as personal")
    func productUpdateNotPersonal() async {
        guard await ToneClassifier.shared.isAvailable else { return }
        let tone = await ToneClassifier.shared.tone(
            subject: "You can now add or remove GreenPower in the Amber app",
            preview: "We've launched new features to help you manage your energy plan."
        )
        #expect(tone != .personal)
    }

    @Test("a terms of service notice does not classify as personal")
    func tosNotPersonal() async {
        guard await ToneClassifier.shared.isAvailable else { return }
        let tone = await ToneClassifier.shared.tone(
            subject: "Learn more about our updated Terms of Service",
            preview: "Every couple of years, we update our Terms of Service."
        )
        #expect(tone != .personal)
    }
}

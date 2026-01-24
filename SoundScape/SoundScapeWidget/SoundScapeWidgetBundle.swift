import SwiftUI
import WidgetKit

@main
struct SoundScapeWidgetBundle: WidgetBundle {
    var body: some Widget {
        StandByWidget()

        // Control Center widget for iOS 18+
        if #available(iOS 18.0, *) {
            SoundScapeControl()
        }
    }
}

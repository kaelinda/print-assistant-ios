import SwiftUI

enum DesignTokens {
    enum Color {
        static let accent = SwiftUI.Color(red: 94 / 255, green: 92 / 255, blue: 230 / 255)
        static let success = SwiftUI.Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
        static let destructive = SwiftUI.Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255)
        static let warning = SwiftUI.Color(red: 255 / 255, green: 149 / 255, blue: 0 / 255)
    }

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let field: CGFloat = 18
        static let card: CGFloat = 22
        static let control: CGFloat = 26
        static let sheet: CGFloat = 30
    }

    enum Motion {
        static let fast = Animation.easeOut(duration: 0.18)
        static let standard = Animation.spring(duration: 0.28, bounce: 0.08)
    }

    static let minimumHitTarget: CGFloat = 44
}

import SwiftUI
import UIKit

enum DesignTokens {
    enum Color {
        static let canvas = adaptive(
            light: UIColor(red: 247 / 255, green: 247 / 255, blue: 249 / 255, alpha: 1),
            dark: UIColor(red: 18 / 255, green: 19 / 255, blue: 22 / 255, alpha: 1)
        )
        static let primaryText = adaptive(
            light: UIColor(red: 17 / 255, green: 19 / 255, blue: 24 / 255, alpha: 1),
            dark: UIColor(red: 244 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1)
        )
        static let secondaryText = adaptive(
            light: UIColor(red: 115 / 255, green: 122 / 255, blue: 134 / 255, alpha: 1),
            dark: UIColor(red: 176 / 255, green: 181 / 255, blue: 190 / 255, alpha: 1)
        )
        static let tertiaryText = adaptive(
            light: UIColor(red: 102 / 255, green: 109 / 255, blue: 121 / 255, alpha: 1),
            dark: UIColor(red: 148 / 255, green: 154 / 255, blue: 164 / 255, alpha: 1)
        )
        static let stateSurface = adaptive(
            light: UIColor(red: 236 / 255, green: 238 / 255, blue: 255 / 255, alpha: 1),
            dark: UIColor(red: 46 / 255, green: 48 / 255, blue: 72 / 255, alpha: 1)
        )
        static let accent = adaptive(
            light: UIColor(red: 94 / 255, green: 92 / 255, blue: 230 / 255, alpha: 1),
            dark: UIColor(red: 148 / 255, green: 146 / 255, blue: 255 / 255, alpha: 1)
        )
        static let success = adaptive(
            light: UIColor(red: 52 / 255, green: 199 / 255, blue: 89 / 255, alpha: 1),
            dark: UIColor(red: 48 / 255, green: 209 / 255, blue: 88 / 255, alpha: 1)
        )
        static let destructive = adaptive(
            light: UIColor(red: 255 / 255, green: 59 / 255, blue: 48 / 255, alpha: 1),
            dark: UIColor(red: 255 / 255, green: 69 / 255, blue: 58 / 255, alpha: 1)
        )
        static let warning = adaptive(
            light: UIColor(red: 255 / 255, green: 149 / 255, blue: 0 / 255, alpha: 1),
            dark: UIColor(red: 255 / 255, green: 159 / 255, blue: 10 / 255, alpha: 1)
        )
        static let cardFill = adaptive(
            light: UIColor(white: 1, alpha: 0.84),
            dark: UIColor(white: 1, alpha: 0.08)
        )
        static let hairline = adaptive(
            light: UIColor(white: 1, alpha: 0.78),
            dark: UIColor(white: 1, alpha: 0.16)
        )
        static let selectedFill = adaptive(
            light: UIColor(white: 1, alpha: 0.56),
            dark: UIColor(white: 1, alpha: 0.14)
        )
        static let shadow = adaptive(
            light: UIColor(red: 20 / 255, green: 26 / 255, blue: 41 / 255, alpha: 0.13),
            dark: UIColor(white: 0, alpha: 0.45)
        )

        private static func adaptive(light: UIColor, dark: UIColor) -> SwiftUI.Color {
            SwiftUI.Color(uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            })
        }
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

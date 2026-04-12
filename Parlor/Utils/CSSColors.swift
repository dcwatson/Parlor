//
//  CSSColors.swift
//  Bender
//
//  Created by Daniel Watson on 4/4/25.
//

import SwiftUI

extension Color {

    public init(hexRGBA: UInt64) {
        self.init(
            red: Double((hexRGBA & 0xFF00_0000) >> 24) / 255.0,
            green: Double((hexRGBA & 0x00FF_0000) >> 16) / 255.0,
            blue: Double((hexRGBA & 0x0000_FF00) >> 8) / 255.0,
            opacity: Double(hexRGBA & 0x0000_00FF) / 255.0
        )
    }

    public init(hexRGB: UInt64) {
        self.init(
            red: Double((hexRGB & 0x00FF_0000) >> 16) / 255.0,
            green: Double((hexRGB & 0x0000_FF00) >> 8) / 255.0,
            blue: Double(hexRGB & 0x0000_00FF) / 255.0
        )
    }

    public init?(css: String) {
        if css.hasPrefix("#") {
            let hexString = String(css.dropFirst())
            guard hexString.count == 6 || hexString.count == 8 else {
                return nil
            }
            let finalHex = hexString.count == 6 ? hexString + "FF" : hexString
            let scanner = Scanner(string: finalHex)
            var hexValue: UInt64 = 0
            guard scanner.scanHexInt64(&hexValue) else {
                return nil
            }
            self.init(hexRGBA: hexValue)
        } else if let color = CSS.namedColor[css.lowercased()] {
            self.init(color)
        }
        else {
            return nil
        }
    }

    public init?(hexString: String) {
        self.init(css: "#\(hexString)")
    }

    struct CSS {
        public static let aliceblue = Color(hexRGB: 0xF0F8FF)
        public static let antiquewhite = Color(hexRGB: 0xFAEBD7)
        public static let aqua = Color(hexRGB: 0x00FFFF)
        public static let aquamarine = Color(hexRGB: 0x7FFFD4)
        public static let azure = Color(hexRGB: 0xF0FFFF)
        public static let beige = Color(hexRGB: 0xF5F5DC)
        public static let bisque = Color(hexRGB: 0xFFE4C4)
        public static let black = Color(hexRGB: 0x000000)
        public static let blanchedalmond = Color(hexRGB: 0xFFEBCD)
        public static let blue = Color(hexRGB: 0x0000FF)
        public static let blueviolet = Color(hexRGB: 0x8A2BE2)
        public static let brown = Color(hexRGB: 0xA52A2A)
        public static let burlywood = Color(hexRGB: 0xDEB887)
        public static let cadetblue = Color(hexRGB: 0x5F9EA0)
        public static let chartreuse = Color(hexRGB: 0x7FFF00)
        public static let chocolate = Color(hexRGB: 0xD2691E)
        public static let coral = Color(hexRGB: 0xFF7F50)
        public static let cornflowerblue = Color(hexRGB: 0x6495ED)
        public static let cornsilk = Color(hexRGB: 0xFFF8DC)
        public static let crimson = Color(hexRGB: 0xDC143C)
        public static let cyan = Color(hexRGB: 0x00FFFF)
        public static let darkblue = Color(hexRGB: 0x00008B)
        public static let darkcyan = Color(hexRGB: 0x008B8B)
        public static let darkgoldenrod = Color(hexRGB: 0xB8860B)
        public static let darkgray = Color(hexRGB: 0xA9A9A9)
        public static let darkgreen = Color(hexRGB: 0x006400)
        public static let darkgrey = Color(hexRGB: 0xA9A9A9)
        public static let darkkhaki = Color(hexRGB: 0xBDB76B)
        public static let darkmagenta = Color(hexRGB: 0x8B008B)
        public static let darkolivegreen = Color(hexRGB: 0x556B2F)
        public static let darkorange = Color(hexRGB: 0xFF8C00)
        public static let darkorchid = Color(hexRGB: 0x9932CC)
        public static let darkred = Color(hexRGB: 0x8B0000)
        public static let darksalmon = Color(hexRGB: 0xE9967A)
        public static let darkseagreen = Color(hexRGB: 0x8FBC8F)
        public static let darkslateblue = Color(hexRGB: 0x483D8B)
        public static let darkslategray = Color(hexRGB: 0x2F4F4F)
        public static let darkslategrey = Color(hexRGB: 0x2F4F4F)
        public static let darkturquoise = Color(hexRGB: 0x00CED1)
        public static let darkviolet = Color(hexRGB: 0x9400D3)
        public static let deeppink = Color(hexRGB: 0xFF1493)
        public static let deepskyblue = Color(hexRGB: 0x00BFFF)
        public static let dimgray = Color(hexRGB: 0x696969)
        public static let dimgrey = Color(hexRGB: 0x696969)
        public static let dodgerblue = Color(hexRGB: 0x1E90FF)
        public static let firebrick = Color(hexRGB: 0xB22222)
        public static let floralwhite = Color(hexRGB: 0xFFFAF0)
        public static let forestgreen = Color(hexRGB: 0x228B22)
        public static let fuchsia = Color(hexRGB: 0xFF00FF)
        public static let gainsboro = Color(hexRGB: 0xDCDCDC)
        public static let ghostwhite = Color(hexRGB: 0xF8F8FF)
        public static let gold = Color(hexRGB: 0xFFD700)
        public static let goldenrod = Color(hexRGB: 0xDAA520)
        public static let gray = Color(hexRGB: 0x808080)
        public static let green = Color(hexRGB: 0x008000)
        public static let greenyellow = Color(hexRGB: 0xADFF2F)
        public static let grey = Color(hexRGB: 0x808080)
        public static let honeydew = Color(hexRGB: 0xF0FFF0)
        public static let hotpink = Color(hexRGB: 0xFF69B4)
        public static let indianred = Color(hexRGB: 0xCD5C5C)
        public static let indigo = Color(hexRGB: 0x4B0082)
        public static let ivory = Color(hexRGB: 0xFFFFF0)
        public static let khaki = Color(hexRGB: 0xF0E68C)
        public static let lavender = Color(hexRGB: 0xE6E6FA)
        public static let lavenderblush = Color(hexRGB: 0xFFF0F5)
        public static let lawngreen = Color(hexRGB: 0x7CFC00)
        public static let lemonchiffon = Color(hexRGB: 0xFFFACD)
        public static let lightblue = Color(hexRGB: 0xADD8E6)
        public static let lightcoral = Color(hexRGB: 0xF08080)
        public static let lightcyan = Color(hexRGB: 0xE0FFFF)
        public static let lightgoldenrodyellow = Color(hexRGB: 0xFAFAD2)
        public static let lightgray = Color(hexRGB: 0xD3D3D3)
        public static let lightgreen = Color(hexRGB: 0x90EE90)
        public static let lightgrey = Color(hexRGB: 0xD3D3D3)
        public static let lightpink = Color(hexRGB: 0xFFB6C1)
        public static let lightsalmon = Color(hexRGB: 0xFFA07A)
        public static let lightseagreen = Color(hexRGB: 0x20B2AA)
        public static let lightskyblue = Color(hexRGB: 0x87CEFA)
        public static let lightslategray = Color(hexRGB: 0x778899)
        public static let lightslategrey = Color(hexRGB: 0x778899)
        public static let lightsteelblue = Color(hexRGB: 0xB0C4DE)
        public static let lightyellow = Color(hexRGB: 0xFFFFE0)
        public static let lime = Color(hexRGB: 0x00FF00)
        public static let limegreen = Color(hexRGB: 0x32CD32)
        public static let linen = Color(hexRGB: 0xFAF0E6)
        public static let magenta = Color(hexRGB: 0xFF00FF)
        public static let maroon = Color(hexRGB: 0x800000)
        public static let mediumaquamarine = Color(hexRGB: 0x66CDAA)
        public static let mediumblue = Color(hexRGB: 0x0000CD)
        public static let mediumorchid = Color(hexRGB: 0xBA55D3)
        public static let mediumpurple = Color(hexRGB: 0x9370DB)
        public static let mediumseagreen = Color(hexRGB: 0x3CB371)
        public static let mediumslateblue = Color(hexRGB: 0x7B68EE)
        public static let mediumspringgreen = Color(hexRGB: 0x00FA9A)
        public static let mediumturquoise = Color(hexRGB: 0x48D1CC)
        public static let mediumvioletred = Color(hexRGB: 0xC71585)
        public static let midnightblue = Color(hexRGB: 0x191970)
        public static let mintcream = Color(hexRGB: 0xF5FFFA)
        public static let mistyrose = Color(hexRGB: 0xFFE4E1)
        public static let moccasin = Color(hexRGB: 0xFFE4B5)
        public static let navajowhite = Color(hexRGB: 0xFFDEAD)
        public static let navy = Color(hexRGB: 0x000080)
        public static let oldlace = Color(hexRGB: 0xFDF5E6)
        public static let olive = Color(hexRGB: 0x808000)
        public static let olivedrab = Color(hexRGB: 0x6B8E23)
        public static let orange = Color(hexRGB: 0xFFA500)
        public static let orangered = Color(hexRGB: 0xFF4500)
        public static let orchid = Color(hexRGB: 0xDA70D6)
        public static let palegoldenrod = Color(hexRGB: 0xEEE8AA)
        public static let palegreen = Color(hexRGB: 0x98FB98)
        public static let paleturquoise = Color(hexRGB: 0xAFEEEE)
        public static let palevioletred = Color(hexRGB: 0xDB7093)
        public static let papayawhip = Color(hexRGB: 0xFFEFD5)
        public static let peachpuff = Color(hexRGB: 0xFFDAB9)
        public static let peru = Color(hexRGB: 0xCD853F)
        public static let pink = Color(hexRGB: 0xFFC0CB)
        public static let plum = Color(hexRGB: 0xDDA0DD)
        public static let powderblue = Color(hexRGB: 0xB0E0E6)
        public static let purple = Color(hexRGB: 0x800080)
        public static let rebeccapurple = Color(hexRGB: 0x663399)
        public static let red = Color(hexRGB: 0xFF0000)
        public static let rosybrown = Color(hexRGB: 0xBC8F8F)
        public static let royalblue = Color(hexRGB: 0x4169E1)
        public static let saddlebrown = Color(hexRGB: 0x8B4513)
        public static let salmon = Color(hexRGB: 0xFA8072)
        public static let sandybrown = Color(hexRGB: 0xF4A460)
        public static let seagreen = Color(hexRGB: 0x2E8B57)
        public static let seashell = Color(hexRGB: 0xFFF5EE)
        public static let sienna = Color(hexRGB: 0xA0522D)
        public static let silver = Color(hexRGB: 0xC0C0C0)
        public static let skyblue = Color(hexRGB: 0x87CEEB)
        public static let slateblue = Color(hexRGB: 0x6A5ACD)
        public static let slategray = Color(hexRGB: 0x708090)
        public static let slategrey = Color(hexRGB: 0x708090)
        public static let snow = Color(hexRGB: 0xFFFAFA)
        public static let springgreen = Color(hexRGB: 0x00FF7F)
        public static let steelblue = Color(hexRGB: 0x4682B4)
        public static let tan = Color(hexRGB: 0xD2B48C)
        public static let teal = Color(hexRGB: 0x008080)
        public static let thistle = Color(hexRGB: 0xD8BFD8)
        public static let tomato = Color(hexRGB: 0xFF6347)
        public static let turquoise = Color(hexRGB: 0x40E0D0)
        public static let violet = Color(hexRGB: 0xEE82EE)
        public static let wheat = Color(hexRGB: 0xF5DEB3)
        public static let white = Color(hexRGB: 0xFFFFFF)
        public static let whitesmoke = Color(hexRGB: 0xF5F5F5)
        public static let yellow = Color(hexRGB: 0xFFFF00)
        public static let yellowgreen = Color(hexRGB: 0x9ACD32)

        public static let namedColor: [String: Color] = [
            "aliceblue": CSS.aliceblue,
            "antiquewhite": CSS.antiquewhite,
            "aqua": CSS.aqua,
            "aquamarine": CSS.aquamarine,
            "azure": CSS.azure,
            "beige": CSS.beige,
            "bisque": CSS.bisque,
            "black": CSS.black,
            "blanchedalmond": CSS.blanchedalmond,
            "blue": CSS.blue,
            "blueviolet": CSS.blueviolet,
            "brown": CSS.brown,
            "burlywood": CSS.burlywood,
            "cadetblue": CSS.cadetblue,
            "chartreuse": CSS.chartreuse,
            "chocolate": CSS.chocolate,
            "coral": CSS.coral,
            "cornflowerblue": CSS.cornflowerblue,
            "cornsilk": CSS.cornsilk,
            "crimson": CSS.crimson,
            "cyan": CSS.cyan,
            "darkblue": CSS.darkblue,
            "darkcyan": CSS.darkcyan,
            "darkgoldenrod": CSS.darkgoldenrod,
            "darkgray": CSS.darkgray,
            "darkgreen": CSS.darkgreen,
            "darkgrey": CSS.darkgrey,
            "darkkhaki": CSS.darkkhaki,
            "darkmagenta": CSS.darkmagenta,
            "darkolivegreen": CSS.darkolivegreen,
            "darkorange": CSS.darkorange,
            "darkorchid": CSS.darkorchid,
            "darkred": CSS.darkred,
            "darksalmon": CSS.darksalmon,
            "darkseagreen": CSS.darkseagreen,
            "darkslateblue": CSS.darkslateblue,
            "darkslategray": CSS.darkslategray,
            "darkslategrey": CSS.darkslategrey,
            "darkturquoise": CSS.darkturquoise,
            "darkviolet": CSS.darkviolet,
            "deeppink": CSS.deeppink,
            "deepskyblue": CSS.deepskyblue,
            "dimgray": CSS.dimgray,
            "dimgrey": CSS.dimgrey,
            "dodgerblue": CSS.dodgerblue,
            "firebrick": CSS.firebrick,
            "floralwhite": CSS.floralwhite,
            "forestgreen": CSS.forestgreen,
            "fuchsia": CSS.fuchsia,
            "gainsboro": CSS.gainsboro,
            "ghostwhite": CSS.ghostwhite,
            "gold": CSS.gold,
            "goldenrod": CSS.goldenrod,
            "gray": CSS.gray,
            "green": CSS.green,
            "greenyellow": CSS.greenyellow,
            "grey": CSS.grey,
            "honeydew": CSS.honeydew,
            "hotpink": CSS.hotpink,
            "indianred": CSS.indianred,
            "indigo": CSS.indigo,
            "ivory": CSS.ivory,
            "khaki": CSS.khaki,
            "lavender": CSS.lavender,
            "lavenderblush": CSS.lavenderblush,
            "lawngreen": CSS.lawngreen,
            "lemonchiffon": CSS.lemonchiffon,
            "lightblue": CSS.lightblue,
            "lightcoral": CSS.lightcoral,
            "lightcyan": CSS.lightcyan,
            "lightgoldenrodyellow": CSS.lightgoldenrodyellow,
            "lightgray": CSS.lightgray,
            "lightgreen": CSS.lightgreen,
            "lightgrey": CSS.lightgrey,
            "lightpink": CSS.lightpink,
            "lightsalmon": CSS.lightsalmon,
            "lightseagreen": CSS.lightseagreen,
            "lightskyblue": CSS.lightskyblue,
            "lightslategray": CSS.lightslategray,
            "lightslategrey": CSS.lightslategrey,
            "lightsteelblue": CSS.lightsteelblue,
            "lightyellow": CSS.lightyellow,
            "lime": CSS.lime,
            "limegreen": CSS.limegreen,
            "linen": CSS.linen,
            "magenta": CSS.magenta,
            "maroon": CSS.maroon,
            "mediumaquamarine": CSS.mediumaquamarine,
            "mediumblue": CSS.mediumblue,
            "mediumorchid": CSS.mediumorchid,
            "mediumpurple": CSS.mediumpurple,
            "mediumseagreen": CSS.mediumseagreen,
            "mediumslateblue": CSS.mediumslateblue,
            "mediumspringgreen": CSS.mediumspringgreen,
            "mediumturquoise": CSS.mediumturquoise,
            "mediumvioletred": CSS.mediumvioletred,
            "midnightblue": CSS.midnightblue,
            "mintcream": CSS.mintcream,
            "mistyrose": CSS.mistyrose,
            "moccasin": CSS.moccasin,
            "navajowhite": CSS.navajowhite,
            "navy": CSS.navy,
            "oldlace": CSS.oldlace,
            "olive": CSS.olive,
            "olivedrab": CSS.olivedrab,
            "orange": CSS.orange,
            "orangered": CSS.orangered,
            "orchid": CSS.orchid,
            "palegoldenrod": CSS.palegoldenrod,
            "palegreen": CSS.palegreen,
            "paleturquoise": CSS.paleturquoise,
            "palevioletred": CSS.palevioletred,
            "papayawhip": CSS.papayawhip,
            "peachpuff": CSS.peachpuff,
            "peru": CSS.peru,
            "pink": CSS.pink,
            "plum": CSS.plum,
            "powderblue": CSS.powderblue,
            "purple": CSS.purple,
            "rebeccapurple": CSS.rebeccapurple,
            "red": CSS.red,
            "rosybrown": CSS.rosybrown,
            "royalblue": CSS.royalblue,
            "saddlebrown": CSS.saddlebrown,
            "salmon": CSS.salmon,
            "sandybrown": CSS.sandybrown,
            "seagreen": CSS.seagreen,
            "seashell": CSS.seashell,
            "sienna": CSS.sienna,
            "silver": CSS.silver,
            "skyblue": CSS.skyblue,
            "slateblue": CSS.slateblue,
            "slategray": CSS.slategray,
            "slategrey": CSS.slategrey,
            "snow": CSS.snow,
            "springgreen": CSS.springgreen,
            "steelblue": CSS.steelblue,
            "tan": CSS.tan,
            "teal": CSS.teal,
            "thistle": CSS.thistle,
            "tomato": CSS.tomato,
            "turquoise": CSS.turquoise,
            "violet": CSS.violet,
            "wheat": CSS.wheat,
            "white": CSS.white,
            "whitesmoke": CSS.whitesmoke,
            "yellow": CSS.yellow,
            "yellowgreen": CSS.yellowgreen,
        ]
    }
}

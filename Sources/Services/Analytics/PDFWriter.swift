import CoreGraphics
import CoreText
import Foundation

/// Minimal paginated text-to-PDF renderer used by exports and reports.
enum PDFWriter {
    /// US Letter at 72 dpi.
    static let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792)

    private static let margin: CGFloat = 54
    private static let bodySize: CGFloat = 11
    private static let titleSize: CGFloat = 18
    private static let subtitleSize: CGFloat = 12

    static func makePDF(title: String, subtitle: String = "", bodyLines: [String]) -> Data {
        let data = NSMutableData()
        var mediaBox = pageSize

        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        let titleFont = CTFontCreateWithName("Helvetica-Bold" as CFString, titleSize, nil)
        let subtitleFont = CTFontCreateWithName("Helvetica" as CFString, subtitleSize, nil)
        let bodyFont = CTFontCreateWithName("Helvetica" as CFString, bodySize, nil)
        let ink = CGColor(gray: 0, alpha: 1)

        let bodyLineHeight = bodySize * 1.5
        let usableWidth = mediaBox.width - margin * 2

        context.beginPDFPage(nil)
        context.textMatrix = .identity

        var y = mediaBox.height - margin

        func newPage() {
            context.endPDFPage()
            context.beginPDFPage(nil)
            context.textMatrix = .identity
            y = mediaBox.height - margin
        }

        func draw(_ text: String, font: CTFont, lineStride: CGFloat) {
            for fragment in wrap(text, font: font, maxWidth: usableWidth) {
                if y - lineStride < margin {
                    newPage()
                }
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: ink
                ]
                guard let attributed = CFAttributedStringCreate(kCFAllocatorDefault, fragment as CFString, attributes as CFDictionary) else {
                    continue
                }
                let line = CTLineCreateWithAttributedString(attributed)
                context.textPosition = CGPoint(x: margin, y: y)
                CTLineDraw(line, context)
                y -= lineStride
            }
        }

        draw(title, font: titleFont, lineStride: titleSize * 1.5)
        if !subtitle.isEmpty {
            draw(subtitle, font: subtitleFont, lineStride: subtitleSize * 1.5)
        }
        y -= bodyLineHeight

        for bodyLine in bodyLines {
            draw(bodyLine, font: bodyFont, lineStride: bodyLineHeight)
        }

        context.endPDFPage()
        context.closePDF()

        return data as Data
    }

    /// Greedy word wrap so long lines stay inside the page margins.
    private static func wrap(_ text: String, font: CTFont, maxWidth: CGFloat) -> [String] {
        guard !text.isEmpty else { return [""] }

        func width(of string: String) -> CGFloat {
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            guard let attributed = CFAttributedStringCreate(kCFAllocatorDefault, string as CFString, attributes as CFDictionary) else {
                return .greatestFiniteMagnitude
            }
            let line = CTLineCreateWithAttributedString(attributed)
            return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        }

        var lines: [String] = []
        var current = ""

        for word in text.split(separator: " ", omittingEmptySubsequences: false) {
            let candidate = current.isEmpty ? String(word) : "\(current) \(word)"
            if width(of: candidate) <= maxWidth || current.isEmpty {
                current = candidate
            } else {
                lines.append(current)
                current = String(word)
            }
        }
        if !current.isEmpty {
            lines.append(current)
        }
        return lines.isEmpty ? [""] : lines
    }
}

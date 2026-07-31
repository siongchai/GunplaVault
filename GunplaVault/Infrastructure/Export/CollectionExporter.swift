import Foundation
import UIKit

enum CollectionExporter {
    static func csv(items: [CollectionItem]) -> String {
        var lines = ["Name,Series,Grade,Scale,Status,Release Year,Price Paid,Acquired Date,Build Hours"]
        let formatter = ISO8601DateFormatter()

        for item in items.sorted(by: { $0.name < $1.name }) {
            let price = item.pricePaid.map { String(format: "%.2f", $0) } ?? ""
            let hours = String(format: "%.1f", item.totalBuildSeconds / 3600)
            let fields = [
                escape(item.name),
                escape(item.series),
                item.grade.rawValue,
                item.scale,
                item.status.displayName,
                String(item.releaseYear),
                price,
                formatter.string(from: item.acquiredDate),
                hours
            ]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    static func pdf(items: [CollectionItem], profile: UserProfile?, snapshot: AnalyticsSnapshot) throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("GunplaVault-Report.pdf")

        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 40

            func draw(_ text: String, font: UIFont, color: UIColor = .black) {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let size = text.size(withAttributes: attrs)
                text.draw(at: CGPoint(x: 40, y: y), withAttributes: attrs)
                y += size.height + 8
            }

            draw("GUNPLA VAULT — Collection Report", font: .boldSystemFont(ofSize: 20), color: UIColor(red: 0.22, green: 0.47, blue: 0.96, alpha: 1))
            if let profile {
                draw("Builder: \(profile.displayName)", font: .systemFont(ofSize: 12), color: .darkGray)
            }
            draw("Generated: \(Date().formatted(date: .abbreviated, time: .shortened))", font: .systemFont(ofSize: 11), color: .gray)
            y += 8

            draw("Summary", font: .boldSystemFont(ofSize: 14))
            draw("Total kits: \(snapshot.totalKits)", font: .systemFont(ofSize: 12))
            draw("Completed: \(snapshot.completedKits) (\(Int(snapshot.completionRate * 100))%)", font: .systemFont(ofSize: 12))
            draw("Total spent: \(formatCurrency(snapshot.totalSpent))", font: .systemFont(ofSize: 12))
            draw("Build hours: \(String(format: "%.1f", snapshot.hoursBuilt))", font: .systemFont(ofSize: 12))
            y += 8

            draw("Collection", font: .boldSystemFont(ofSize: 14))
            for item in items.prefix(40) {
                if y > pageRect.height - 60 {
                    context.beginPage()
                    y = 40
                }
                let line = "• \(item.name) [\(item.grade.rawValue)] — \(item.status.displayName)"
                draw(line, font: .systemFont(ofSize: 11))
            }
        }

        try data.write(to: url)
        return url
    }

    static func writeCSVToTempFile(_ csv: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("GunplaVault-Collection.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

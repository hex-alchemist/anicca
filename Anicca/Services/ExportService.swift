import Foundation
import UIKit
import PDFKit

final class ExportService {
    static let shared = ExportService()
    private init() {}

    // MARK: - JSON Export

    func exportJSON(checkIns: [CheckIn]) throws -> URL {
        struct EntryOut: Encodable {
            let name: String
            let center: String
            let intensity: Int
        }
        struct CheckInOut: Encodable {
            let id: UUID
            let created_at: String
            let note: String?
            let emotions: [EntryOut]
        }
        struct ExportPayload: Encodable {
            let exported_at: String
            let total_check_ins: Int
            let check_ins: [CheckInOut]
        }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        let payload = ExportPayload(
            exported_at: iso.string(from: Date()),
            total_check_ins: checkIns.count,
            check_ins: checkIns
                .sorted { $0.createdAt > $1.createdAt }
                .map { checkIn in
                    CheckInOut(
                        id: checkIn.id,
                        created_at: iso.string(from: checkIn.createdAt),
                        note: checkIn.note,
                        emotions: checkIn.entries.map {
                            EntryOut(
                                name: $0.emotionName,
                                center: $0.energyCenterRaw,
                                intensity: $0.intensity
                            )
                        }
                    )
                }
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(payload)
            let url = try tempFileURL(suffix: "json")
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            throw AppError.exportFailed("Could not write JSON file.")
        }
    }

    // MARK: - PDF Export

    func exportPDF(checkIns: [CheckIn], profile: UserProfile) throws -> URL {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let url: URL
        do {
            url = try tempFileURL(suffix: "pdf")
        } catch {
            throw AppError.exportFailed("Could not allocate PDF file.")
        }

        do {
            try renderer.writePDF(to: url) { context in
                drawCoverPage(context, pageRect: pageRect, profile: profile, totalCheckIns: checkIns.count)
                drawSummaryPage(context, pageRect: pageRect, checkIns: checkIns)
                drawCheckInPages(context, pageRect: pageRect, checkIns: checkIns)
            }
        } catch {
            throw AppError.exportFailed("Could not write PDF file.")
        }
        return url
    }

    // MARK: - Helpers

    private func tempFileURL(suffix: String) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let filename = "anicca_export_\(formatter.string(from: Date())).\(suffix)"
        return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    }

    private func drawCoverPage(_ context: UIGraphicsPDFRendererContext, pageRect: CGRect, profile: UserProfile, totalCheckIns: Int) {
        context.beginPage()
        UIColor(red: 0.96, green: 0.94, blue: 0.98, alpha: 1).setFill()
        context.fill(pageRect)

        let centerX = pageRect.midX

        // Logo (sparkles symbol)
        let logoConfig = UIImage.SymbolConfiguration(pointSize: 80, weight: .semibold)
        if let logo = UIImage(systemName: "sparkles", withConfiguration: logoConfig)?.withTintColor(UIColor(red: 0.49, green: 0.36, blue: 0.75, alpha: 1), renderingMode: .alwaysOriginal) {
            let size = logo.size
            logo.draw(at: CGPoint(x: centerX - size.width / 2, y: 200))
        }

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let title = "Anicca"
        let titleSize = title.size(withAttributes: titleAttrs)
        title.draw(at: CGPoint(x: centerX - titleSize.width / 2, y: 300), withAttributes: titleAttrs)

        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ]
        let name = profile.displayName ?? profile.email
        let nameSize = name.size(withAttributes: nameAttrs)
        name.draw(at: CGPoint(x: centerX - nameSize.width / 2, y: 360), withAttributes: nameAttrs)

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let dateText = "Exported \(formatter.string(from: Date()))"
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        let dateSize = dateText.size(withAttributes: dateAttrs)
        dateText.draw(at: CGPoint(x: centerX - dateSize.width / 2, y: 395), withAttributes: dateAttrs)

        let countText = "\(totalCheckIns) check-ins logged"
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor(red: 0.49, green: 0.36, blue: 0.75, alpha: 1)
        ]
        let countSize = countText.size(withAttributes: countAttrs)
        countText.draw(at: CGPoint(x: centerX - countSize.width / 2, y: 430), withAttributes: countAttrs)

        drawFooter(context, pageRect: pageRect, page: 1)
    }

    private func drawSummaryPage(_ context: UIGraphicsPDFRendererContext, pageRect: CGRect, checkIns: [CheckIn]) {
        context.beginPage()

        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor(red: 0.49, green: 0.36, blue: 0.75, alpha: 1)
        ]
        "Chakra Balance Summary".draw(at: CGPoint(x: 40, y: 50), withAttributes: headerAttrs)

        let insightsService = InsightsService()
        let allEntries = checkIns.flatMap { $0.entries }

        let rowAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.black
        ]
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        var y: CGFloat = 110
        let centerColX: CGFloat = 60
        let countColX: CGFloat = 220
        let statusColX: CGFloat = 320
        let avgColX: CGFloat = 460

        "Center".draw(at: CGPoint(x: centerColX, y: y), withAttributes: boldAttrs)
        "Entries".draw(at: CGPoint(x: countColX, y: y), withAttributes: boldAttrs)
        "Status".draw(at: CGPoint(x: statusColX, y: y), withAttributes: boldAttrs)
        "Avg".draw(at: CGPoint(x: avgColX, y: y), withAttributes: boldAttrs)
        y += 24

        for center in EnergyCenter.allCases {
            let centerEntries = allEntries.filter { $0.energyCenter == center }
            let count = centerEntries.count
            let score = insightsService.balanceScore(for: center, in: allEntries)
            let status = insightsService.centerStatus(score: score)
            let avg: Double = count == 0 ? 0 : Double(centerEntries.reduce(0) { $0 + $1.intensity }) / Double(count)

            // Color dot
            let dotPath = UIBezierPath(ovalIn: CGRect(x: 40, y: y + 4, width: 12, height: 12))
            UIColor(cgColor: UIColor(red: chakraRGB(center).0, green: chakraRGB(center).1, blue: chakraRGB(center).2, alpha: 1).cgColor).setFill()
            dotPath.fill()

            center.displayName.draw(at: CGPoint(x: centerColX, y: y), withAttributes: rowAttrs)
            "\(count)".draw(at: CGPoint(x: countColX, y: y), withAttributes: rowAttrs)
            status.displayName.draw(at: CGPoint(x: statusColX, y: y), withAttributes: rowAttrs)
            String(format: "%.1f", avg).draw(at: CGPoint(x: avgColX, y: y), withAttributes: rowAttrs)
            y += 26
        }

        drawFooter(context, pageRect: pageRect, page: 2)
    }

    private func drawCheckInPages(_ context: UIGraphicsPDFRendererContext, pageRect: CGRect, checkIns: [CheckIn]) {
        let sorted = checkIns.sorted { $0.createdAt > $1.createdAt }
        var y: CGFloat = 50
        var pageNum = 3

        context.beginPage()
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor(red: 0.49, green: 0.36, blue: 0.75, alpha: 1)
        ]
        "Check-ins".draw(at: CGPoint(x: 40, y: y), withAttributes: headerAttrs)
        y += 50

        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]
        let emotionAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.black
        ]
        let noteAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        for checkIn in sorted {
            if y > pageRect.height - 120 {
                drawFooter(context, pageRect: pageRect, page: pageNum)
                pageNum += 1
                context.beginPage()
                y = 50
            }

            formatter.string(from: checkIn.createdAt).draw(at: CGPoint(x: 40, y: y), withAttributes: dateAttrs)
            y += 18

            for entry in checkIn.entries {
                let rgb = chakraRGB(entry.energyCenter)
                let dotPath = UIBezierPath(ovalIn: CGRect(x: 50, y: y + 4, width: 8, height: 8))
                UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1).setFill()
                dotPath.fill()

                let intensityDots = String(repeating: "●", count: entry.intensity) + String(repeating: "○", count: 5 - entry.intensity)
                "\(entry.emotionName)  \(intensityDots)".draw(at: CGPoint(x: 66, y: y), withAttributes: emotionAttrs)
                y += 16
            }

            if let note = checkIn.note, !note.isEmpty {
                let noteBox = CGRect(x: 50, y: y, width: pageRect.width - 100, height: 40)
                note.draw(in: noteBox, withAttributes: noteAttrs)
                y += 44
            }
            y += 10
        }
        drawFooter(context, pageRect: pageRect, page: pageNum)
    }

    private func drawFooter(_ context: UIGraphicsPDFRendererContext, pageRect: CGRect, page: Int) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        let footer = "Anicca — Read your energy. Understand yourself."
        footer.draw(at: CGPoint(x: 40, y: pageRect.height - 30), withAttributes: attrs)
        let pageStr = "\(page)"
        let size = pageStr.size(withAttributes: attrs)
        pageStr.draw(at: CGPoint(x: pageRect.width - size.width - 40, y: pageRect.height - 30), withAttributes: attrs)
    }

    private func chakraRGB(_ center: EnergyCenter) -> (CGFloat, CGFloat, CGFloat) {
        switch center {
        case .root:     return (0.75, 0.22, 0.17)
        case .sacral:   return (0.90, 0.49, 0.13)
        case .solar:    return (0.95, 0.77, 0.06)
        case .heart:    return (0.15, 0.68, 0.38)
        case .throat:   return (0.16, 0.50, 0.73)
        case .thirdEye: return (0.56, 0.27, 0.68)
        case .crown:    return (0.61, 0.35, 0.71)
        }
    }
}

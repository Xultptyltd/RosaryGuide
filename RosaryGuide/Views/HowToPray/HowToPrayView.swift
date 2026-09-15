import SwiftUI

struct HowToPrayView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    BilingualStack(
                        text: HowToPrayContent.introduction,
                        language: settings.language,
                        font: .body
                    )

                    rosaryDiagram

                    ForEach(HowToPrayContent.steps) { step in
                        HStack(alignment: .top, spacing: 14) {
                            Text("\(step.id)")
                                .font(.headline)
                                .foregroundStyle(AppTheme.ivory)
                                .frame(width: 32, height: 32)
                                .background(AppTheme.marianBlue, in: Circle())
                            VStack(alignment: .leading, spacing: 6) {
                                Text(step.title.primary(for: settings.language))
                                    .font(.headline)
                                if settings.language == .bilingual {
                                    Text(step.title.latin)
                                        .font(.subheadline)
                                        .italic()
                                        .foregroundStyle(.secondary)
                                }
                                Text(step.body)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("When to pray which mysteries")
                            .font(.title3.weight(.semibold))
                        ForEach(HowToPrayContent.weekdayGuide, id: \.0) { day, rule in
                            HStack(alignment: .top) {
                                Text(day)
                                    .font(.subheadline.weight(.semibold))
                                    .frame(width: 92, alignment: .leading)
                                Text(rule)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text(HowToPrayContent.beadsNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("How to Pray")
        }
    }

    private var rosaryDiagram: some View {
        VStack(spacing: 10) {
            Canvas { context, size in
                let midX = size.width / 2
                var y: CGFloat = 16
                let crucifix = CGRect(x: midX - 7, y: y, width: 14, height: 22)
                context.fill(Path(crucifix), with: .color(AppTheme.gold))
                context.fill(Path(CGRect(x: midX - 12, y: y + 6, width: 24, height: 6)), with: .color(AppTheme.gold))
                y += 36
                for i in 0..<5 {
                    let isOurFather = i == 0 || i == 4
                    let radius: CGFloat = isOurFather ? 8 : 5
                    let rect = CGRect(x: midX - radius, y: y, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(isOurFather ? AppTheme.gold : AppTheme.marianBlue))
                    y += isOurFather ? 22 : 16
                }
                let loopCenter = CGPoint(x: midX, y: y + 70)
                for decade in 0..<5 {
                    let angle0 = (Double(decade) / 5.0) * .pi * 2 - .pi / 2
                    for bead in 0..<11 {
                        let t = Double(bead) / 11.0
                        let angle = angle0 + t * (.pi * 2 / 5.0) * 0.82
                        let radius: CGFloat = bead == 0 ? 7 : 4.5
                        let x = loopCenter.x + cos(angle) * 78
                        let yb = loopCenter.y + sin(angle) * 58
                        let color = bead == 0 ? AppTheme.gold : AppTheme.marianBlue
                        let rect = CGRect(x: x - radius, y: yb - radius, width: radius * 2, height: radius * 2)
                        context.fill(Path(ellipseIn: rect), with: .color(color))
                    }
                }
            }
            .frame(height: 280)
            .background(AppTheme.deepNavy.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text("Placeholder diagram — crucifix, opening beads, five decades")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel("Diagram of a five-decade rosary")
    }
}

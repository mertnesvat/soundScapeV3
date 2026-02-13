import SwiftUI

struct SoundScienceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(ScienceContentDataSource.sections) { section in
                        sectionView(section)
                    }
                }
                .padding()
            }
            .navigationTitle(LocalizedStringKey("Sound Science"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    @ViewBuilder
    private func sectionView(_ section: ScienceSection) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text(section.title)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            // Articles in section
            ForEach(section.content) { article in
                articleView(article)
            }
        }
    }

    @ViewBuilder
    private func articleView(_ article: ScienceArticle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Article header
            HStack(spacing: 8) {
                Image(systemName: article.icon)
                    .foregroundStyle(.secondary)
                Text(article.title)
                    .font(.headline)
            }

            // Body text
            Text(article.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Bullet points
            VStack(alignment: .leading, spacing: 6) {
                ForEach(article.bulletPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\u{2022}")
                            .foregroundStyle(.purple)
                        Text(point)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SoundScienceView()
        .preferredColorScheme(.dark)
}

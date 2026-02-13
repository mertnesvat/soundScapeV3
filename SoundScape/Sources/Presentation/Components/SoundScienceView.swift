import SwiftUI

struct SoundScienceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with brain icon
                    headerSection

                    // Iterate over all science sections
                    ForEach(SoundScienceContent.sections) { section in
                        sectionView(section)
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle(LocalizedStringKey("Sound Science"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 80, height: 80)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 36))
                        .foregroundColor(.purple)
                }
                Text(LocalizedStringKey("Sound Science"))
                    .font(.title2)
                    .fontWeight(.bold)
                Text(LocalizedStringKey("Learn how sounds affect your brain"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical)
    }

    private func sectionView(_ section: ScienceSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.title3)
                    .foregroundColor(.purple)
                Text(section.title)
                    .font(.headline)
            }

            // Items
            ForEach(section.items) { item in
                itemView(item)
            }
        }
    }

    private func itemView(_ item: ScienceItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.subheadline)
                    .foregroundColor(.purple)
                    .frame(width: 24)
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(item.points, id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\u{2022}")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text(point)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.leading, 32)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    SoundScienceView()
        .preferredColorScheme(.dark)
}

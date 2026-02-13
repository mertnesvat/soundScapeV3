import SwiftUI

struct CategoryFilterView: View {
    @Binding var selectedCategory: SoundCategory?
    var showingFavorites: Bool = false
    var onSelectFavorites: (() -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: String(localized: "All"),
                    icon: "square.grid.2x2.fill",
                    isSelected: selectedCategory == nil && !showingFavorites
                ) {
                    selectedCategory = nil
                }

                if let onSelectFavorites = onSelectFavorites {
                    CategoryChip(
                        title: String(localized: "Favorites"),
                        icon: "heart.fill",
                        isSelected: showingFavorites
                    ) {
                        onSelectFavorites()
                    }
                }

                ForEach(SoundCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.localizedName,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.purple : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CategoryFilterView(selectedCategory: .constant(nil))
        .preferredColorScheme(.dark)
        .background(Color(.systemBackground))
}

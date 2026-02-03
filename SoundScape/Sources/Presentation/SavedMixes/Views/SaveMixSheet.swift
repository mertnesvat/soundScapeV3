import SwiftUI

struct SaveMixSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mixName = ""
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Mix name", text: $mixName)
                } footer: {
                    Text("Give your mix a memorable name")
                }
            }
            .navigationTitle(LocalizedStringKey("Save Mix"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(mixName)
                        dismiss()
                    }
                    .disabled(mixName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(200)])
    }
}

#Preview {
    SaveMixSheet(onSave: { name in
        print("Saved: \(name)")
    })
    .preferredColorScheme(.dark)
}

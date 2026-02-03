import SwiftUI

struct InviteBuddyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SleepBuddyService.self) private var buddyService

    @State private var selectedTab = 0
    @State private var inviteCode = ""
    @State private var enteredCode = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isPairingSuccessful = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Mode", selection: $selectedTab) {
                    Text("Share Code").tag(0)
                    Text("Enter Code").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    shareCodeView
                } else {
                    enterCodeView
                }

                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizedStringKey("Pair with Buddy"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(LocalizedStringKey("Pairing Error"), isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert(LocalizedStringKey("Paired Successfully!"), isPresented: $isPairingSuccessful) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                if let buddy = buddyService.buddy {
                    Text("You're now paired with \(buddy.name). You can see each other's sleep streaks!")
                }
            }
            .onAppear {
                if inviteCode.isEmpty {
                    inviteCode = buddyService.generateInviteCode()
                }
            }
        }
    }

    // MARK: - Share Code View

    private var shareCodeView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "qrcode")
                    .font(.system(size: 48))
                    .foregroundStyle(.purple)

                Text("Your Invite Code")
                    .font(.headline)

                Text("Share this code with your friend")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)

            // Code Display
            HStack(spacing: 8) {
                ForEach(Array(inviteCode.enumerated()), id: \.offset) { _, char in
                    Text(String(char))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .frame(width: 44, height: 56)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()

            // Expiration notice
            if let invite = buddyService.pendingInvite {
                Text("Code expires in \(timeUntilExpiration(invite.expiresAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Share Button
            ShareLink(item: "Join me as a Sleep Buddy in SoundScape! Enter code: \(inviteCode)") {
                Label(LocalizedStringKey("Share Code"), systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.purple.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            // Copy Button
            Button {
                UIPasteboard.general.string = inviteCode
            } label: {
                Label(LocalizedStringKey("Copy Code"), systemImage: "doc.on.doc")
                    .font(.subheadline)
                    .foregroundStyle(.purple)
            }

            // Generate new code
            Button {
                inviteCode = buddyService.generateInviteCode()
            } label: {
                Text("Generate New Code")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
        .padding()
    }

    // MARK: - Enter Code View

    private var enterCodeView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.purple)

                Text("Enter Friend's Code")
                    .font(.headline)

                Text("Ask your friend to share their invite code")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)

            // Code Entry
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    let digit = getDigit(at: index)
                    Text(digit.isEmpty ? " " : digit)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .frame(width: 44, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.tertiarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(index == enteredCode.count ? Color.purple : Color.clear, lineWidth: 2)
                        )
                }
            }
            .padding()

            // Hidden TextField for input
            TextField("", text: $enteredCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: enteredCode) { _, newValue in
                    // Limit to 6 digits
                    if newValue.count > 6 {
                        enteredCode = String(newValue.prefix(6))
                    }
                    // Only allow numbers
                    enteredCode = newValue.filter { $0.isNumber }
                }

            // Numpad hint
            Text("Tap to enter code")
                .font(.caption)
                .foregroundStyle(.secondary)
                .onTapGesture {
                    // Focus the text field
                    UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                }

            // Pair Button
            Button {
                pairWithCode()
            } label: {
                Text("Pair with Buddy")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(enteredCode.count == 6 ? AnyShapeStyle(.purple.gradient) : AnyShapeStyle(Color.gray))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(enteredCode.count != 6)
            .padding(.horizontal)

            // Clear button
            if !enteredCode.isEmpty {
                Button {
                    enteredCode = ""
                } label: {
                    Text("Clear")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func getDigit(at index: Int) -> String {
        guard index < enteredCode.count else { return "" }
        let stringIndex = enteredCode.index(enteredCode.startIndex, offsetBy: index)
        return String(enteredCode[stringIndex])
    }

    private func timeUntilExpiration(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }

    private func pairWithCode() {
        guard enteredCode.count == 6 else { return }

        if buddyService.acceptInvite(code: enteredCode) {
            isPairingSuccessful = true
        } else {
            errorMessage = "Invalid or expired invite code. Please check the code and try again."
            showingError = true
        }
    }
}

#Preview {
    InviteBuddyView()
        .environment(SleepBuddyService())
        .preferredColorScheme(.dark)
}

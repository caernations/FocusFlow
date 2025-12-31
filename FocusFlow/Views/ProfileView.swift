import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var showSignOutAlert = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        VStack(spacing: 16) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.4, green: 0.8, blue: 1.0),
                                                Color(red: 0.6, green: 0.4, blue: 1.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)

                                Text(authManager.currentUser?.name.prefix(1).uppercased() ?? "U")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(spacing: 4) {
                                Text(authManager.currentUser?.name ?? "User")
                                    .font(.title2.bold())

                                Text(authManager.currentUser?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            // Auth method badge
                            if let authMethod = authManager.currentUser?.authMethod {
                                HStack(spacing: 6) {
                                    Image(systemName: authMethod == .apple ? "apple.logo" : (authMethod == .google ? "g.circle.fill" : "envelope.fill"))
                                        .font(.caption)
                                    Text("Signed in with \(authMethod.rawValue.capitalized)")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.1))
                                )
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)

                        // Settings sections
                        VStack(spacing: 20) {
                            // Account section
                            settingsSection(title: "Account") {
                                settingsRow(icon: "person.fill", title: "Edit Profile", color: .blue)
                                settingsRow(icon: "bell.fill", title: "Notifications", color: .orange)
                                settingsRow(icon: "lock.fill", title: "Privacy", color: .green)
                            }

                            // App section
                            settingsSection(title: "App") {
                                settingsRow(icon: "paintbrush.fill", title: "Appearance", color: .purple)
                                settingsRow(icon: "chart.bar.fill", title: "Data & Analytics", color: .blue)
                                settingsRow(icon: "arrow.clockwise", title: "Restore Purchases", color: .indigo)
                            }

                            // Export section
                            settingsSection(title: "Export Data") {
                                exportRow(icon: "doc.text.fill", title: "Export as CSV", color: .green) {
                                    exportData(format: .csv)
                                }
                                exportRow(icon: "doc.badge.gearshape.fill", title: "Export as JSON", color: .blue) {
                                    exportData(format: .json)
                                }
                                exportRow(icon: "doc.richtext.fill", title: "Generate PDF Report", color: .red) {
                                    exportData(format: .pdf)
                                }
                            }

                            // About section
                            settingsSection(title: "About") {
                                settingsRow(icon: "star.fill", title: "Rate App", color: .yellow)
                                settingsRow(icon: "envelope.fill", title: "Contact Support", color: .blue)
                                settingsRow(icon: "doc.text.fill", title: "Terms & Privacy", color: .gray)
                            }

                            // Sign out button
                            Button(action: { showSignOutAlert = true }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                )
                            }
                            .padding(.horizontal)

                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 20)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
    }

    // MARK: - Export Methods

    enum ExportFormat {
        case csv, json, pdf
    }

    private func exportData(format: ExportFormat) {
        let persistence = PersistenceManager.shared
        let sessions = persistence.fetchSessions(from: Date.distantPast, to: Date())

        guard !sessions.isEmpty else {
            // TODO: Show alert for no data
            return
        }

        let exporter = DataExporter.shared
        var fileURL: URL?

        switch format {
        case .csv:
            fileURL = exporter.exportToCSV(sessions: sessions)
        case .json:
            fileURL = exporter.exportToJSON(sessions: sessions)
        case .pdf:
            fileURL = exporter.generatePDFReport(sessions: sessions)
        }

        if let url = fileURL {
            shareItems = [url]
            showShareSheet = true
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                content()
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private func settingsRow(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 0) {
            Button(action: {}) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .frame(width: 28)

                    Text(title)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            Divider()
                .padding(.leading, 56)
        }
    }

    private func exportRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .frame(width: 28)

                    Text(title)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            Divider()
                .padding(.leading, 56)
        }
    }
}

#Preview {
    ProfileView()
}

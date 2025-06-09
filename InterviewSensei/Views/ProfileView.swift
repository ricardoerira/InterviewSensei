import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingEditProfile = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(viewModel.userProfile?.name ?? "User")
                                .font(.title2)
                                .bold()
                            Text(viewModel.userProfile?.email ?? "user@example.com")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
               
                
                // Preferences Section
                Section(header: Text("Preferences")) {
                    NavigationLink {
                        PreferenceView(title: "Job Roles", items: JobRole.allCases.map { $0.rawValue })
                    } label: {
                        Label("Job Roles", systemImage: "briefcase.fill")
                    }
                    
                    NavigationLink {
                        PreferenceView(title: "Experience Levels", items: ExperienceLevel.allCases.map { $0.rawValue })
                    } label: {
                        Label("Experience Levels", systemImage: "chart.bar.fill")
                    }
                    
                    NavigationLink {
                        PreferenceView(title: "Question Categories", items: QuestionCategory.allCases.map { $0.rawValue })
                    } label: {
                        Label("Question Categories", systemImage: "list.bullet")
                    }
                }
                
                // Voice Settings Section
                Section(header: Text("Voice Settings")) {
                    Picker("Voice", selection: $viewModel.selectedVoice) {
                        ForEach(VoiceOption.allCases, id: \.self) { voice in
                            Text(voice.rawValue).tag(voice)
                        }
                    }
                    
                    Toggle("Enable Voice Feedback", isOn: $viewModel.enableVoiceFeedback)
                }
                
                // Data Management Section
                Section(header: Text("Data Management")) {
                    Button(action: { viewModel.exportData() }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { showingDeleteConfirmation = true }) {
                        Label("Delete Account", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditProfile = true
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(profile: viewModel.userProfile)
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteAccount()
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
        }
    }
}

struct PreferenceView: View {
    let title: String
    let items: [String]
    @State private var selectedItems: Set<String> = []
    
    var body: some View {
        List {
            ForEach(items, id: \.self) { item in
                Toggle(item, isOn: Binding(
                    get: { selectedItems.contains(item) },
                    set: { isSelected in
                        if isSelected {
                            selectedItems.insert(item)
                        } else {
                            selectedItems.remove(item)
                        }
                    }
                ))
            }
        }
        .navigationTitle(title)
    }
}

struct EditProfileView: View {
    let profile: UserProfile?
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // TODO: Save profile changes
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = profile?.name ?? ""
                email = profile?.email ?? ""
            }
        }
    }
}

class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var selectedVoice: VoiceOption = .default
    @Published var enableVoiceFeedback = true
    
    var totalSessions: Int { Int(userProfile?.totalSessions ?? 0) }
    var averageScore: Double { 0.0 } // TODO: Implement
    var totalQuestions: Int { 0 } // TODO: Implement
    var mostPracticedRole: String? { userProfile?.mostPracticedRole }
    
    func exportData() {
        // TODO: Implement data export
    }
    
    func deleteAccount() {
        // TODO: Implement account deletion
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 

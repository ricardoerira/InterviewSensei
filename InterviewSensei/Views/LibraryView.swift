import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var selectedTimeFrame: TimeFrame = .week
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Statistics Section
                    HStack {
                        StatisticView(title: "Total Sessions", value: "\(viewModel.totalSessions)")
                        StatisticView(title: "Total Questions", value: "\(viewModel.totalQuestions)")
                    }
                    .padding()
                    
                    // Recent Responses
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Responses")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.recentResponses) { response in
                            ResponseRow(response: response)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.exportData() }) {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { viewModel.clearHistory() }) {
                            Label("Clear History", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity)
    }
}

struct ResponseRow: View {
    let response: Response
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(response.question?.text ?? "No question text available")
                .font(.headline)
            
            HStack {
                Label(formatDuration(response.duration), systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ResponseDetailView: View {
    let response: Response
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Question
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question")
                            .font(.headline)
                        Text(response.question?.text ?? "No question text available")
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    // Response
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Response")
                            .font(.headline)
                        Text(response.text ?? "")
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Response Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

enum TimeFrame: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

class LibraryViewModel: ObservableObject {
    @Published var recentResponses: [Response] = []
    @Published var savedQuestions: [Question] = []
    
    var totalSessions: Int { 0 } // TODO: Implement
    var totalQuestions: Int { 0 } // TODO: Implement
    
    func exportData() {
        // TODO: Implement data export
    }
    
    func clearHistory() {
        // TODO: Implement history clearing
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
    }
} 

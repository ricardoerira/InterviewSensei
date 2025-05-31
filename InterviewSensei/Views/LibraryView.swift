import SwiftUI
import Charts

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var showingResponseDetail = false
    @State private var selectedResponse: Response?
    
    var body: some View {
        NavigationView {
            List {
                // Analytics Section
                Section(header: Text("Analytics")) {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Time Frame", selection: $selectedTimeFrame) {
                            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                                Text(timeFrame.rawValue).tag(timeFrame)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Chart(viewModel.analytics) { data in
                            LineMark(
                                x: .value("Date", data.date),
                                y: .value("Score", data.score)
                            )
                            .foregroundStyle(.blue)
                            
                            AreaMark(
                                x: .value("Date", data.date),
                                y: .value("Score", data.score)
                            )
                            .foregroundStyle(.blue.opacity(0.1))
                        }
                        .frame(height: 200)
                        
                        HStack {
                            StatisticView(
                                title: "Total Sessions",
                                value: "\(viewModel.totalSessions)"
                            )
                            
                            StatisticView(
                                title: "Avg. Score",
                                value: String(format: "%.1f", viewModel.averageScore)
                            )
                            
                            StatisticView(
                                title: "Questions",
                                value: "\(viewModel.totalQuestions)"
                            )
                        }
                    }
                    .padding(.vertical)
                }
                
                // Recent Responses Section
                Section(header: Text("Recent Responses")) {
                    ForEach(viewModel.recentResponses) { response in
                        ResponseRow(response: response)
                            .onTapGesture {
                                selectedResponse = response
                                showingResponseDetail = true
                            }
                    }
                }
                
                // Saved Questions Section
                Section(header: Text("Saved Questions")) {
                    ForEach(viewModel.savedQuestions) { question in
                        QuestionRow(question: question)
                    }
                }
            }
            .navigationTitle("Library")
            .sheet(isPresented: $showingResponseDetail) {
                if let response = selectedResponse {
                    ResponseDetailView(response: response)
                }
            }
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
                Spacer()
                Label(String(format: "%.0f%%", response.averageFeedbackScore * 100),
                      systemImage: "star.fill")
                    .foregroundColor(.yellow)
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
                    
                    // Metrics
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Metrics")
                            .font(.headline)
                        
                        MetricRow(title: "Duration", value: formatDuration(response.duration))
                        MetricRow(title: "Filler Words", value: "\(response.fillerWordCount)")
                        MetricRow(title: "Speaking Pace", value: String(format: "%.1f wpm", response.speakingPace))
                        MetricRow(title: "Clarity", value: String(format: "%.0f%%", response.clarityScore * 100))
                        MetricRow(title: "Confidence", value: String(format: "%.0f%%", response.confidenceScore * 100))
                    }
                    
                    // Feedback
                    if let feedback = response.feedback as? Set<Feedback>, !feedback.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Feedback")
                                .font(.headline)
                            
                            ForEach(Array(feedback), id: \.id) { feedback in
                                FeedbackRow(feedback: feedback)
                            }
                        }
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
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
        .padding(.vertical, 4)
    }
}

struct FeedbackRow: View {
    let feedback: Feedback
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(feedback.category ?? "")
                    .font(.subheadline)
                Spacer()
                Text("\(Int(feedback.score * 100))%")
                    .font(.subheadline)
                    .foregroundColor(feedback.isPositive ? .green : feedback.isNeutral ? .yellow : .red)
            }
            
            Text(feedback.text ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

enum TimeFrame: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct AnalyticsData: Identifiable {
    let id = UUID()
    let date: Date
    let score: Double
}

class LibraryViewModel: ObservableObject {
    @Published var analytics: [AnalyticsData] = []
    @Published var recentResponses: [Response] = []
    @Published var savedQuestions: [Question] = []
    
    var totalSessions: Int { 0 } // TODO: Implement
    var averageScore: Double { 0.0 } // TODO: Implement
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

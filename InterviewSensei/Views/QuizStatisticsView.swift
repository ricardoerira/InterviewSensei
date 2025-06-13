import SwiftUI
import CoreData

// MARK: - Overall Statistics Section
private struct OverallStatisticsSection: View {
    let quizResults: [QuizResult]
    let averageScore: Double
    
    var body: some View {
        Section("Overall Statistics") {
            StatisticRow(
                title: "Total Quizzes",
                value: "\(quizResults.count)",
                icon: "list.bullet.clipboard",
                color: .blue
            )
            
            StatisticRow(
                title: "Average Score",
                value: String(format: "%.1f%%", averageScore),
                icon: "chart.bar.fill",
                color: .green
            )
        }
    }
}

// MARK: - Category Statistics Section
private struct CategoryStatisticsSection: View {
    let categoryStats: [(category: String, count: Int, averageScore: Double)]
    
    var body: some View {
        Section("Category Statistics") {
            ForEach(categoryStats, id: \.category) { stat in
                CategoryStatRow(stat: stat)
            }
        }
    }
}

private struct CategoryStatRow: View {
    let stat: (category: String, count: Int, averageScore: Double)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stat.category)
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Text("Quizzes: \(stat.count)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(String(format: "Avg: %.1f%%", stat.averageScore))
                    .font(.subheadline)
                    .foregroundColor(stat.averageScore >= 70 ? .green : .red)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

// MARK: - Quiz History Section
private struct QuizHistorySection: View {
    let quizResults: [QuizResult]
    let onResultSelected: (QuizResult) -> Void
    
    var body: some View {
        Section("Quiz History") {
            if quizResults.isEmpty {
                Text("No quiz history available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(quizResults) { result in
                    QuizResultRow(result: result)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onResultSelected(result)
                        }
                }
            }
        }
    }
}

// MARK: - Main View
struct QuizStatisticsView: View {
    @StateObject private var viewModel = QuizStatisticsViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedResult: QuizResult?
    @StateObject var sheetManager = SheetMananger()

    class SheetMananger: ObservableObject {
        @Published var showingDetail = false
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Overall Statistics
                        VStack(spacing: 16) {
                            Text("Overall Statistics")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                            
                            StatisticRow(
                                title: "Total Quizzes",
                                value: "\(viewModel.quizResults.count)",
                                icon: "list.bullet.clipboard",
                                color: .blue
                            )
                            .liquidGlass()
                            
                            StatisticRow(
                                title: "Average Score",
                                value: String(format: "%.1f%%", viewModel.calculateAverageScore()),
                                icon: "chart.bar.fill",
                                color: .green
                            )
                            .liquidGlass()
                        }
                        .padding()
                        
                        // Category Statistics
                        VStack(spacing: 16) {
                            Text("Category Statistics")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                            
                            ForEach(viewModel.calculateCategoryStats(), id: \.category) { stat in
                                CategoryStatRow(stat: stat)
                                    .liquidGlass()
                            }
                        }
                        .padding()
                        
                        // Quiz History
                        VStack(spacing: 16) {
                            Text("Quiz History")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                            
                            if viewModel.quizResults.isEmpty {
                                Text("No quiz history available")
                                    .foregroundColor(.white)
                                    .italic()
                                    .liquidGlass()
                            } else {
                                ForEach(viewModel.quizResults) { result in
                                    QuizResultRow(result: result)
                                        .liquidGlass()
                                        .onTapGesture {
                                            selectedResult = result
                                            sheetManager.showingDetail = true
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.top, 90)
                }
            }
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Text("Quiz Statistics")
//                        .font(.title)
//                        .bold()
//                        .foregroundColor(.white.opacity(0.8))
//                        .padding(.leading, 80)
//                }
//               
//            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .alert("Clear History", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    viewModel.deleteAllResults()
                }
            } message: {
                Text("Are you sure you want to delete all quiz history? This action cannot be undone.")
            }
            .refreshable {
                viewModel.loadQuizResults()
            }
            .sheet(isPresented: $sheetManager.showingDetail) {
                if let result = selectedResult {
                    QuizResultView(
                        score: Int(result.score),
                        totalQuestions: Int(result.totalQuestions),
                        onPracticeAgain: {
                            sheetManager.showingDetail = false
                        },
                        category: result.category,
                        date: result.date,
                        questions: (result.questions?.allObjects as? [QuizQuestionResult]) ?? [],
                        duration: result.duration
                    )
                }
            }
        }
    }
}

// MARK: - Preview Provider
struct QuizStatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        QuizStatisticsView()
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text(value)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

struct QuizResultRow: View {
    let result: QuizResult
    
    private var percentage: Double {
        guard result.totalQuestions > 0 else { return 0 }
        return (Double(result.score) / Double(result.totalQuestions)) * 100
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.category ?? "Unknown Category")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(dateFormatter.string(from: result.date ?? Date()))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack {
                Text("Score: \(result.score)/\(result.totalQuestions)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(String(format: "%.1f%%", percentage))
                    .font(.subheadline)
                    .foregroundColor(percentage >= 70 ? .green : .red)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 8)
                        .opacity(0.3)
                        .foregroundColor(.white.opacity(0.3))
                    
                    Rectangle()
                        .frame(width: min(CGFloat(percentage) / 100.0 * geometry.size.width, geometry.size.width), height: 8)
                        .foregroundColor(percentage >= 70 ? .green : .red)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}

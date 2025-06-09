import SwiftUI
import CoreData

struct QuizStatisticsView: View {
    @StateObject private var viewModel = QuizStatisticsViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedResult: QuizResult?
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
            
            List {
                // Overall Statistics Section
                Section("Overall Statistics") {
                    StatisticRow(
                        title: "Total Quizzes",
                        value: "\(viewModel.quizResults.count)",
                        icon: "list.bullet.clipboard",
                        color: .blue
                    )
            
                    
                    StatisticRow(
                        title: "Average Score",
                        value: String(format: "%.1f%%", viewModel.calculateAverageScore()),
                        icon: "chart.bar.fill",
                        color: .green
                    )
                }
                
                // Category Statistics Section
                Section("Category Statistics") {
                    ForEach(viewModel.calculateCategoryStats(), id: \.category) { stat in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stat.category)
                                .font(.headline)
                            
                            HStack {
                                Text("Quizzes: \(stat.count)")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "Avg: %.1f%%", stat.averageScore))
                                    .font(.subheadline)
                                    .foregroundColor(stat.averageScore >= 70 ? .green : .red)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                }
                
                // Quiz History Section
                Section("Quiz History") {
                    if viewModel.quizResults.isEmpty {
                        Text("No quiz history available")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(viewModel.quizResults) { result in
                            QuizResultRow(result: result)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    Task { @MainActor in
                                           selectedResult = result
                                           showingDetail = true
                                       }
                                    
                                }
                                    
                                
                        }
                    }
                }
            }
            .navigationTitle("Quiz Statistics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showDeleteConfirmation = true
                    } label: {
                        Label("Clear History", systemImage: "trash")
                    }
                }
            }
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
            .sheet(isPresented: $showingDetail) {
                if let result = selectedResult {
                    QuizResultView(
                        score: Int(result.score),
                        totalQuestions: Int(result.totalQuestions),
                        onPracticeAgain: {
                            showingDetail = false
                        },
                        category: result.category,
                        date: result.date,
                        questions: (result.questions?.allObjects as? [QuizQuestionResult]) ?? []
                    )
                }
            }
        }
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
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .bold()
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
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
                Spacer()
                Text(dateFormatter.string(from: result.date ?? Date()))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Score: \(result.score)/\(result.totalQuestions)")
                    .font(.subheadline)
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
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(percentage) / 100.0 * geometry.size.width, geometry.size.width), height: 8)
                        .foregroundColor(percentage >= 70 ? .green : .red)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
        }
        .padding(.vertical, 8)
    }
}


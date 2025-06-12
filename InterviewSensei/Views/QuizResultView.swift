import SwiftUI

struct ResultData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
    let color: Color
}

struct PieSlice: Shape {
    let startAngle: Double
    let endAngle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center,
                   radius: radius,
                   startAngle: .degrees(startAngle),
                   endAngle: .degrees(endAngle),
                   clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct DonutChart: View {
    let data: [ResultData]
    let progress: Double
    
    private var total: Int {
        data.reduce(0) { $0 + $1.count }
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                let startAngle = index == 0 ? 0.0 : data[..<index].reduce(0.0) { $0 + (Double($1.count) / Double(total) * 360.0) }
                let endAngle = startAngle + (Double(item.count) / Double(total) * 360.0)
                
                PieSlice(startAngle: startAngle, endAngle: endAngle)
                    .fill(item.color)
                    .opacity(progress)
            }
            
            // Center circle for donut effect
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: 100, height: 100)
        }
    }
}

struct QuizResultView: View {
    let score: Int
    let totalQuestions: Int
    let onPracticeAgain: () -> Void
    let category: String?
    let date: Date?
    let questions: [QuizQuestionResult]?
    let duration: TimeInterval?

    @State private var animatedScore: Double = 0
    @State private var showQuestions: Bool = false
    @State private var isAppeared: Bool = false

    private var percentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return (Double(score) / Double(totalQuestions)) * 100
    }

    private var formattedDuration: String {
        guard let duration = duration else { return "N/A" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Quiz Result")
                        .font(.largeTitle)
                        .bold()
                        .opacity(isAppeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.5), value: isAppeared)
                    
                    if let category = category {
                        Text(category)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .opacity(isAppeared ? 1 : 0)
                            .animation(.easeIn(duration: 0.5).delay(0.2), value: isAppeared)
                    }
                    
                    HStack(spacing: 16) {
                        if let date = date {
                            Label(dateFormatter.string(from: date), systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Label(formattedDuration, systemImage: "clock")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .opacity(isAppeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.3), value: isAppeared)
                }

                // Score Circle
                ZStack {
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.2)
                        .foregroundColor(.blue)

                    Circle()
                        .trim(from: 0.0, to: CGFloat(animatedScore / 100))
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.green, .yellow, .red]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.0), value: animatedScore)

                    VStack {
                        Text(String(format: "%.1f%%", animatedScore))
                            .font(.largeTitle)
                            .bold()
                        Text("\(score) / \(totalQuestions)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 200, height: 200)
                .opacity(isAppeared ? 1 : 0)
                .animation(.easeIn(duration: 0.5).delay(0.4), value: isAppeared)

                // Score Breakdown
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        StatisticView(
                            title: "Correct",
                            value: "\(score)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        StatisticView(
                            title: "Incorrect",
                            value: "\(totalQuestions - score)",
                            icon: "xmark.circle.fill",
                            color: .red
                        )
                    }
                }
                .padding(.horizontal)

                // Questions List
                if let questions = questions {
                    VStack(alignment: .leading, spacing: 16) {
                        Button {
                            withAnimation {
                                showQuestions.toggle()
                            }
                        } label: {
                            HStack {
                                Text("Question Details")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: showQuestions ? "chevron.up" : "chevron.down")
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        if showQuestions {
                            ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                                QuestionResultRow(
                                    questionNumber: index + 1,
                                    question: question
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Practice Again Button
                Button(action: onPracticeAgain) {
                    Text("Practice Again")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("Blue"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 24)
            }
            .padding()
        }
        .onAppear {
            isAppeared = true
            withAnimation(.easeOut(duration: 1.0)) {
                animatedScore = percentage
            }
        }
        .onDisappear {
            isAppeared = false
            animatedScore = 0
        }
    }
}

struct QuestionResultRow: View {
    let questionNumber: Int
    let question: QuizQuestionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Question \(questionNumber)")
                .font(.headline)
            
            Text(question.questionText ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: question.selectedOptionIndex == question.correctOptionIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(question.selectedOptionIndex == question.correctOptionIndex ? .green : .red)
                
                Text("Your answer: \(question.options![Int(question.selectedOptionIndex ?? 0)])")
                    .font(.subheadline)
                
                if question.selectedOptionIndex != question.correctOptionIndex {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("Correct: \(question.options![Int(question.correctOptionIndex)])")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct StatisticView: View {
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct QuizResultView_Previews: PreviewProvider {
    static var previews: some View {
        QuizResultView(
            score: 8,
            totalQuestions: 10,
            onPracticeAgain: {},
            category: "Algorithms",
            date: Date(),
            questions: nil,
            duration: 125.5
        )
    }
}

//
//  QuestionDetector.swift
//  InterviewSensei
//
//  Created by andres on 15/05/25.
//

import Foundation

class QuestionDetector {

    private let questionWords = [
        "what", "why", "how", "where", "when", "which", "who",
        "do", "does", "did", "can", "could", "should", "would",
        "is", "are", "will", "shall", "may", "might"
    ]

    /// Detects questions in a string and returns only the substrings of the questions.
    /// - Parameter text: The input text to analyze.
    /// - Returns: An array of question substrings.
    func detectQuestions(from text: String) -> String {
        return text
        var questions: [String] = []
        
        // Split the text by sentence-ending punctuation
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if it is a question
            if isQuestion(sentence: trimmed) {
                questions.append(trimmed + "?") // Ensure the question ends with "?"
            }
        }
        let singleString = questions.joined(separator: " ")

        return singleString
    }
    
    /// Determines if a sentence is a question.
    /// - Parameter sentence: The sentence to check.
    /// - Returns: `true` if the sentence is a question, `false` otherwise.
    private func isQuestion(sentence: String) -> Bool {
        let lowercased = sentence.lowercased()
        let words = lowercased.components(separatedBy: .whitespacesAndNewlines)

        // Check if it starts with a question word or ends with a question mark
        if let firstWord = words.first, questionWords.contains(firstWord) {
            return true
        }

        return false
    }
}

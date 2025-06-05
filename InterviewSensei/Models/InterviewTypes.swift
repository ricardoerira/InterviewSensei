import Foundation

enum QuestionCategory: String, CaseIterable {
    case behavioral = "Behavioral"
    case technical = "Technical"
    case problemSolving = "Problem Solving"
    case leadership = "Leadership"
    case communication = "Communication"
}

enum InterviewMode: String, CaseIterable {
    case mock = "Mock Interview"
    case practice = "Practice"
    case review = "Review"
}

enum JobRole: String, CaseIterable {
    case softwareEngineer = "Software Engineer"
    case productManager = "Product Manager"
    case dataScientist = "Data Scientist"
    case uxDesigner = "UX Designer"
    case projectManager = "Project Manager"
}

enum ExperienceLevel: String, CaseIterable {
    case entry = "Entry Level"
    case intermediate = "Intermediate"
    case senior = "Senior"
    case lead = "Lead"
    case principal = "Principal"
}

enum VoiceOption: String, CaseIterable {
    case `default` = "Default"
    case male = "Male"
    case female = "Female"
} 
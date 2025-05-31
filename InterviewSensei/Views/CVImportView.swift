import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct CVImportView: View {
    @StateObject private var viewModel: CVImportViewModel
    @State private var isFilePickerPresented = false
    @State private var showDeleteConfirmation = false
    @State private var isLoading = false
    
    init(viewModel: CVImportViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let cv = viewModel.importedCV {
                    ImportedCVContentView(cv: cv, viewModel: viewModel)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Import your CV")
                            .font(.title2)
                            .bold()
                        
                        Text("Upload your CV in PDF or text format to get started")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            isFilePickerPresented = true
                        }) {
                            Label("Choose File", systemImage: "doc.badge.plus")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("CV Import")
            .fileImporter(
                isPresented: $isFilePickerPresented,
                allowedContentTypes: [.pdf, .plainText],
                allowsMultipleSelection: false
            ) { result in
                Task {
                    await handleFileImport(result)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .alert("Success", isPresented: $viewModel.showSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("CV has been successfully deleted")
            }
        }
        // Show loading indicator if isLoading is true
        if isLoading {
            ProgressView("Processing CV...")
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .padding()
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) async {
        isLoading = true
        do {
            let selectedFile = try result.get().first
            guard let fileURL = selectedFile else {
                throw CVProcessingError.invalidFileFormat
            }
            
            // Start accessing the security-scoped resource
            guard fileURL.startAccessingSecurityScopedResource() else {
                throw CVProcessingError.invalidFileFormat
            }
            
            defer {
                // Make sure we release the security-scoped resource when finished
                fileURL.stopAccessingSecurityScopedResource()
            }
            
            // Process the CV
            let cvInfo = try await viewModel.processCVFile(fileURL)
            await MainActor.run {
                viewModel.importedCV = cvInfo
            }
        } catch {
            await MainActor.run {
                viewModel.errorMessage = error.localizedDescription
                viewModel.showError = true
            }
        }
        isLoading = false
    }
}

// New helper view to display imported CV content
private struct ImportedCVContentView: View {
    let cv: CVInfo
    @ObservedObject var viewModel: CVImportViewModel // Use ObservedObject to access viewModel's state
    @State private var showDeleteConfirmation = false // State for delete confirmation within this view
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // CV Information
                Group {
                    Text(cv.name ?? "No Name")
                        .font(.title)
                        .bold()
                    
                    Text(cv.email ?? "No Email")
                        .foregroundColor(.secondary)
                    
                    Text(cv.phone ?? "No Phone")
                        .foregroundColor(.secondary)
                    
                    Text("Summary")
                        .font(.headline)
                    Text(cv.summary ?? "No Summary")
                    
                    // Experience Section
                    // Safely unwrap, cast, and sort experience data
                    let experienceSet = cv.experience as? Set<Experience> ?? []
                    let experienceArray = Array(experienceSet)
                    let sortedExperience = experienceArray.sorted(by: { ($0.startDate ?? Date()) > ($1.startDate ?? Date()) })
                    
                    if !sortedExperience.isEmpty {
                        ExperienceSectionView(experience: sortedExperience)
                    }
                    
                    // Education
                    // Safely unwrap, cast, and sort education data
                    let educationSet = cv.education as? Set<Education> ?? []
                    let educationArray = Array(educationSet)
                    let sortedEducation = educationArray.sorted(by: { ($0.startDate ?? Date()) > ($1.startDate ?? Date()) })
                    
                    if !sortedEducation.isEmpty {
                        EducationSectionView(education: sortedEducation)
                    }
                    
                    // Skills
                    if let skills = cv.skills, !skills.isEmpty {
                        SkillsSectionView(skills: skills)
                    }
                }
                .padding(.horizontal)
            }
        }
        
        // Delete Button
        Button(action: {
            showDeleteConfirmation = true
        }) {
            Label("Delete CV", systemImage: "trash")
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
        }
        .padding()
        .alert("Delete CV", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteCV()
                }
            }
        } message: {
            Text("Are you sure you want to delete this CV? This action cannot be undone.")
        }
        // Alerts for delete operation outcome (moved from main view)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("CV has been successfully deleted")
        }
    }
}

// Helper view for Basic Information section
private struct BasicInfoSectionView: View {
    let cv: CVInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Basic Information")
                .font(.headline)
            
            if let name = cv.name {
                Text(name)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            if let email = cv.email {
                Text(email)
                    .foregroundColor(.secondary)
            }
            
            if let phone = cv.phone {
                Text(phone)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

// Helper view for Professional Summary section
private struct SummarySectionView: View {
    let summary: String?
    
    var body: some View {
        if let summary = summary {
            VStack(alignment: .leading, spacing: 8) {
                Text("Professional Summary")
                    .font(.headline)
                
                Text(summary)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
}

// Helper view for Work Experience section
private struct ExperienceSectionView: View {
    let experience: [Experience]
    
    var body: some View {
        if !experience.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Work Experience")
                    .font(.headline)
                
                ForEach(experience, id: \.id) { experience in
                    ExperienceDetailView(experience: experience)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
}

// Helper view for a single Experience entry
private struct ExperienceDetailView: View {
    let experience: Experience
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let position = experience.position {
                Text(position)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            if let company = experience.company {
                Text(company)
                    .foregroundColor(.secondary)
            }
            
            if let startDate = experience.startDate {
                Text("\(startDate.formatted(date: .abbreviated, time: .omitted)) - \(experience.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "Present")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let description = experience.jobDescription {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// Helper view for Education section
private struct EducationSectionView: View {
    let education: [Education]
    
    var body: some View {
        if !education.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Education")
                    .font(.headline)
                
                ForEach(education, id: \.id) { education in
                    EducationDetailView(education: education)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
}

// Helper view for a single Education entry
private struct EducationDetailView: View {
    let education: Education
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let degree = education.degree {
                Text(degree)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            if let institution = education.institution {
                Text(institution)
                    .foregroundColor(.secondary)
            }
            
            if let field = education.field {
                Text(field)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let startDate = education.startDate {
                Text("\(startDate.formatted(date: .abbreviated, time: .omitted)) - \(education.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "Present")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// Helper view for Skills section
private struct SkillsSectionView: View {
    let skills: [String]?
    
    var body: some View {
        if let skills = skills, !skills.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Skills")
                    .font(.headline)
                
                FlowLayout(spacing: 8) {
                    ForEach(skills, id: \.self) { skill in
                        Text(skill)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(15)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
}

struct CVInfoView: View {
    let cvInfo: CVInfo
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Basic Info
                BasicInfoSectionView(cv: cvInfo)
                
                // Professional Summary
                SummarySectionView(summary: cvInfo.summary)
                
                // Work Experience
                // Safely unwrap, cast, and sort experience data
                let sortedExperience = (cvInfo.experience as? Set<Experience> ?? []).sorted(by: { ($0.startDate ?? Date()) > ($1.startDate ?? Date()) })
                
                if !sortedExperience.isEmpty {
                    ExperienceSectionView(experience: sortedExperience)
                }
                
                // Education
                // Safely unwrap, cast, and sort education data
                let sortedEducation = (cvInfo.education as? Set<Education> ?? []).sorted(by: { ($0.startDate ?? Date()) > ($1.startDate ?? Date()) })
                
                if !sortedEducation.isEmpty {
                    EducationSectionView(education: sortedEducation)
                }
                
                // Skills
                if let skills = cvInfo.skills, !skills.isEmpty {
                    SkillsSectionView(skills: skills)
                }
            }
            .padding()
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, proposal: proposal).offsets
        
        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }
    
    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (offsets: [CGPoint], size: CGSize) {
        guard let containerWidth = proposal.width else {
            return (sizes.map { _ in .zero }, .zero)
        }
        
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for size in sizes {
            if currentX + size.width > containerWidth {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxY = max(maxY, currentY + rowHeight)
        }
        
        return (offsets, CGSize(width: containerWidth, height: maxY))
    }
} 
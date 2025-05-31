import Foundation
import CoreData

@objc(CVInfo)
public class CVInfo: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var email: String?
    @NSManaged public var phone: String?
    @NSManaged public var summary: String?
    @NSManaged public var experience: [Experience]
    @NSManaged public var education: [Education]
    @NSManaged public var skills: [String]
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

@objc(Experience)
public class Experience: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var company: String
    @NSManaged public var position: String
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date?
    @NSManaged public var jobDescription: String?
    @NSManaged public var cvInfo: CVInfo
}

@objc(Education)
public class Education: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var institution: String
    @NSManaged public var degree: String
    @NSManaged public var field: String
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date?
    @NSManaged public var cvInfo: CVInfo
} 
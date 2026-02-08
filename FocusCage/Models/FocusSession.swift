import Foundation

struct FocusSession: Identifiable, Codable {
    let id: UUID
    let profileId: UUID
    let profileName: String
    let profileIconName: String
    let profileColorRaw: String
    let startDate: Date
    var endDate: Date?
    let scheduledEndDate: Date
    let blockedAppCount: Int
    let blockedWebsiteCount: Int
    var wasCompleted: Bool
    
    init(
        id: UUID = UUID(),
        profileId: UUID,
        profileName: String,
        profileIconName: String,
        profileColorRaw: String,
        startDate: Date = Date(),
        endDate: Date? = nil,
        scheduledEndDate: Date,
        blockedAppCount: Int,
        blockedWebsiteCount: Int,
        wasCompleted: Bool = false
    ) {
        self.id = id
        self.profileId = profileId
        self.profileName = profileName
        self.profileIconName = profileIconName
        self.profileColorRaw = profileColorRaw
        self.startDate = startDate
        self.endDate = endDate
        self.scheduledEndDate = scheduledEndDate
        self.blockedAppCount = blockedAppCount
        self.blockedWebsiteCount = blockedWebsiteCount
        self.wasCompleted = wasCompleted
    }
    
    var duration: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }
    
    var durationHours: Double {
        duration / 3600.0
    }
}

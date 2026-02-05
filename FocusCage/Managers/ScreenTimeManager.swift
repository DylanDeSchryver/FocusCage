import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine

class ScreenTimeManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationError: String?
    
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNotifications()
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        switch center.authorizationStatus {
        case .approved:
            isAuthorized = true
        case .denied:
            isAuthorized = false
            authorizationError = "Screen Time access was denied. Please enable it in Settings."
        case .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    @MainActor
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            isAuthorized = true
            authorizationError = nil
        } catch {
            isAuthorized = false
            authorizationError = "Failed to get Screen Time authorization: \(error.localizedDescription)"
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .profileActivated)
            .compactMap { $0.object as? FocusProfile }
            .sink { [weak self] profile in
                self?.activateBlocking(for: profile)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .profileDeactivated)
            .sink { [weak self] _ in
                self?.deactivateBlocking()
            }
            .store(in: &cancellables)
    }
    
    func activateBlocking(for profile: FocusProfile) {
        guard isAuthorized else {
            print("Cannot activate blocking: not authorized")
            return
        }
        
        let selection = profile.blockedApps
        
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        
        let blockedDomains: Set<WebDomain> = Set(profile.blockedWebsites.map { WebDomain(domain: $0.domain) })
        if !blockedDomains.isEmpty {
            store.webContent.blockedByFilter = .specific(blockedDomains)
        } else {
            store.webContent.blockedByFilter = nil
        }
        
        print("Blocking activated for profile: \(profile.name) with \(blockedDomains.count) websites")
    }
    
    func deactivateBlocking() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
        store.webContent.blockedByFilter = nil
        
        print("Blocking deactivated")
    }
    
    func updateBlocking(with selection: FamilyActivitySelection, websites: [BlockedWebsite] = []) {
        guard isAuthorized else { return }
        
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        
        let blockedDomains: Set<WebDomain> = Set(websites.map { WebDomain(domain: $0.domain) })
        if !blockedDomains.isEmpty {
            store.webContent.blockedByFilter = .specific(blockedDomains)
        } else {
            store.webContent.blockedByFilter = nil
        }
    }
    
    func clearAllBlocking() {
        store.clearAllSettings()
    }
}

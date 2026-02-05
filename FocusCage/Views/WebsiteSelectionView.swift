import SwiftUI

struct WebsiteSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var blockedWebsites: [BlockedWebsite]
    @State private var customDomain = ""
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
    private var filteredSuggestions: [BlockedWebsite] {
        if searchText.isEmpty {
            return BlockedWebsite.suggestions
        }
        return BlockedWebsite.suggestions.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.domain.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(.secondary)
                        TextField("Add website (e.g., example.com)", text: $customDomain)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                        
                        if !customDomain.isEmpty {
                            Button {
                                addCustomWebsite()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.indigo)
                            }
                        }
                    }
                } header: {
                    Text("Add Custom Website")
                } footer: {
                    Text("Enter a domain without https:// (e.g., youtube.com)")
                }
                
                if !blockedWebsites.isEmpty {
                    Section("Blocked Websites (\(blockedWebsites.count))") {
                        ForEach(blockedWebsites) { website in
                            HStack {
                                Image(systemName: website.iconName)
                                    .foregroundStyle(.indigo)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(website.displayName)
                                        .fontWeight(.medium)
                                    Text(website.domain)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    removeWebsite(website)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            blockedWebsites.remove(atOffsets: indexSet)
                        }
                    }
                }
                
                Section("Suggested Websites") {
                    ForEach(filteredSuggestions) { website in
                        let isBlocked = blockedWebsites.contains { $0.domain == website.domain }
                        
                        Button {
                            toggleWebsite(website)
                        } label: {
                            HStack {
                                Image(systemName: website.iconName)
                                    .foregroundStyle(isBlocked ? .indigo : .secondary)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(website.displayName)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text(website.domain)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: isBlocked ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isBlocked ? .indigo : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search websites")
            .navigationTitle("Block Websites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func addCustomWebsite() {
        let cleanedDomain = cleanDomain(customDomain)
        guard !cleanedDomain.isEmpty else { return }
        guard !blockedWebsites.contains(where: { $0.domain == cleanedDomain }) else {
            customDomain = ""
            return
        }
        
        let newWebsite = BlockedWebsite(
            domain: cleanedDomain,
            displayName: cleanedDomain,
            iconName: "globe",
            isSuggested: false
        )
        blockedWebsites.append(newWebsite)
        customDomain = ""
    }
    
    private func cleanDomain(_ input: String) -> String {
        var domain = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if domain.hasPrefix("https://") {
            domain = String(domain.dropFirst(8))
        } else if domain.hasPrefix("http://") {
            domain = String(domain.dropFirst(7))
        }
        if domain.hasPrefix("www.") {
            domain = String(domain.dropFirst(4))
        }
        if let slashIndex = domain.firstIndex(of: "/") {
            domain = String(domain[..<slashIndex])
        }
        return domain
    }
    
    private func toggleWebsite(_ website: BlockedWebsite) {
        if let index = blockedWebsites.firstIndex(where: { $0.domain == website.domain }) {
            blockedWebsites.remove(at: index)
        } else {
            blockedWebsites.append(website)
        }
    }
    
    private func removeWebsite(_ website: BlockedWebsite) {
        blockedWebsites.removeAll { $0.id == website.id }
    }
}

#Preview {
    WebsiteSelectionView(blockedWebsites: .constant([]))
}

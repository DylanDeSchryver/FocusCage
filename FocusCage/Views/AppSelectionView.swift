import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: FamilyActivitySelection
    @Binding var blockedWebsites: [BlockedWebsite]
    @State private var showingPicker = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Selection Type", selection: $selectedTab) {
                    Text("Apps").tag(0)
                    Text("Websites").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    appsTab
                } else {
                    websitesTab
                }
            }
            .navigationTitle("Block Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .familyActivityPicker(isPresented: $showingPicker, selection: $selection)
        }
    }
    
    private var appsTab: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "apps.iphone")
                    .font(.system(size: 60))
                    .foregroundStyle(.indigo)
                
                VStack(spacing: 8) {
                    Text("Select Apps to Block")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose apps and categories that will be\ncompletely blocked during focus time")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 20)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(selection.applicationTokens.count)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Apps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 50)
                    
                    VStack(alignment: .leading) {
                        Text("\(selection.categoryTokens.count)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Categories")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            
            Button {
                showingPicker = true
            } label: {
                Label("Choose Apps & Categories", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.indigo)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            
            if selection.applicationTokens.count > 0 || selection.categoryTokens.count > 0 {
                Button(role: .destructive) {
                    selection = FamilyActivitySelection()
                } label: {
                    Label("Clear Selection", systemImage: "trash")
                        .font(.subheadline)
                }
            }
            
            Spacer()
        }
    }
    
    private var websitesTab: some View {
        WebsiteSelectionContent(blockedWebsites: $blockedWebsites)
    }
}

struct WebsiteSelectionContent: View {
    @Binding var blockedWebsites: [BlockedWebsite]
    @State private var customDomain = ""
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
        List {
            Section {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(.secondary)
                    TextField("Add website (e.g., example.com)", text: $customDomain)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .onSubmit {
                            addCustomWebsite()
                        }
                    
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
                Text("Blocked websites work system-wide across all browsers")
            }
            
            if !blockedWebsites.isEmpty {
                Section("Blocked (\(blockedWebsites.count))") {
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
                }
            }
            
            Section("Suggested") {
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
    AppSelectionView(
        selection: .constant(FamilyActivitySelection()),
        blockedWebsites: .constant([])
    )
}

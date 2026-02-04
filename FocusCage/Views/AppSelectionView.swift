import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: FamilyActivitySelection
    @State private var showingPicker = false
    
    var body: some View {
        NavigationStack {
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
                .padding(.top, 40)
                
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
            .navigationTitle("App Selection")
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
}

#Preview {
    AppSelectionView(selection: .constant(FamilyActivitySelection()))
}

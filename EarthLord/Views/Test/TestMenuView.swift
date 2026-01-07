import SwiftUI

struct TestMenuView: View {

    var body: some View {
        List {
            NavigationLink(destination: SupabaseTestView()) {
                HStack(spacing: 15) {
                    Image(systemName: "externaldrive.badge.checkmark")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Supabase Connection Test")
                            .font(.headline)
                        Text("Test database connectivity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            NavigationLink(destination: TerritoryTestView()) {
                HStack(spacing: 15) {
                    Image(systemName: "map.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Territory Test")
                            .font(.headline)
                        Text("View path tracking logs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Development Tests")
    }
}

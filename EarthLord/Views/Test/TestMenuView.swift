import SwiftUI

struct TestMenuView: View {
    @State private var isInsertingTestData = false
    @State private var isFixingDatabase = false
    @State private var isInsertingCollisionTest = false  // Day 19: 碰撞测试
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var successMessage = ""

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

            // 🆕 数据库修复与插入测试领地（龙泉驿）
            Button(action: {
                fixDatabaseAndInsertTerritory()
            }) {
                HStack(spacing: 15) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("🔧 Fix Database & Insert Territory")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("龙泉驿桃花源别墅测试领地 (30.565, 104.265)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if isFixingDatabase {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .padding(.vertical, 8)
            }
            .disabled(isFixingDatabase)

            // 🆕 Day 19: 插入他人领地（碰撞测试）
            Button(action: {
                insertOtherUserTerritory()
            }) {
                HStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("🧪 Insert Other User Territory (Collision Test)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("北边 40m 处插入橙色领地，用于测试碰撞检测")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if isInsertingCollisionTest {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .padding(.vertical, 8)
            }
            .disabled(isInsertingCollisionTest)

            // 插入测试领地按钮（旧版，保留）
            Button(action: {
                insertTestTerritory()
            }) {
                HStack(spacing: 15) {
                    Image(systemName: "location.fill.viewfinder")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Insert Test Territory (Old)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Insert a test territory in Chengdu for indoor testing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if isInsertingTestData {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .padding(.vertical, 8)
            }
            .disabled(isInsertingTestData)
        }
        .navigationTitle("Development Tests")
        .alert("Success!", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(successMessage.isEmpty ? "✅ Test territory inserted! Open the map to see the green polygon." : successMessage)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Fix Database and Insert Territory

    private func fixDatabaseAndInsertTerritory() {
        isFixingDatabase = true

        Task {
            do {
                try await DatabaseFixManager.shared.executeCompleteFixFlow()

                await MainActor.run {
                    isFixingDatabase = false
                    successMessage = "✅ 数据库修复完成！\n✅ 龙泉驿测试领地已插入！\n\n请重启 App 并进入地图页面查看。"
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isFixingDatabase = false
                    errorMessage = "修复失败：\(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }

    // MARK: - Insert Test Territory

    private func insertTestTerritory() {
        isInsertingTestData = true

        Task {
            do {
                try await TerritoryManager.shared.insertTestTerritory()

                await MainActor.run {
                    isInsertingTestData = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isInsertingTestData = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }

    // MARK: - Day 19: Insert Other User Territory (Collision Test)

    private func insertOtherUserTerritory() {
        isInsertingCollisionTest = true

        Task {
            do {
                try await TerritoryManager.shared.insertOtherUserTerritoryForCollisionTest()

                await MainActor.run {
                    isInsertingCollisionTest = false
                    successMessage = "✅ 他人领地已插入（北边 40m）！\n\n橙色多边形应该显示在你北边约 40 米处。\n\n请重启 App 并进入地图页面测试碰撞检测。"
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isInsertingCollisionTest = false
                    errorMessage = "插入失败：\(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
}

import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showingClearIndex = false

    var body: some View {
        Form {
            Section("数据") {
                NavigationLink("隐私与数据", value: AppModel.Route.privacy)
                NavigationLink("隐私政策", value: AppModel.Route.privacyPolicy)
                Button("清除本地文字索引", role: .destructive) {
                    showingClearIndex = true
                }
            }
            Section("支持") {
                NavigationLink("意见反馈", value: AppModel.Route.feedback)
            }
            Section {
                Text("所有扫描、OCR 和 PDF 处理默认在本机完成。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: AppModel.Route.self) { route in
            switch route {
            case .privacy: PrivacyView()
            case .privacyPolicy: PrivacyPolicyView()
            case .feedback: FeedbackView()
            default: EmptyView()
            }
        }
        .confirmationDialog("清除本地文字索引？", isPresented: $showingClearIndex, titleVisibility: .visible) {
            Button("清除索引", role: .destructive) {
                for document in appModel.library.documents {
                    try? appModel.library.updateSearchableText(id: document.id, text: nil)
                }
                appModel.transientMessage = "文字索引已清除"
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("原始文件不会被删除，之后仍可重新识别文字。")
        }
    }
}

struct PrivacyView: View {
    var body: some View {
        List {
            Section("本地处理") {
                Label("扫描、OCR、PDF 生成和文件索引在设备上完成", systemImage: "lock.shield")
                Label("应用不会自动上传原始文件", systemImage: "wifi.slash")
                Label("文件使用 iOS 完整保护存储", systemImage: "checkmark.shield")
            }
            Section("系统权限") {
                Text("相机和照片权限只在你主动启动相应功能时请求。拒绝权限后仍可使用文件导入和已有文件管理。")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("隐私与数据")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("""
            打印助手优先在本机处理你的文档。应用只保存完成工作流所需的文件索引、文件名和处理结果。除非你主动使用系统分享、打印或导出功能，文件不会离开设备。

            你可以随时在设置中清除 OCR 文字索引或删除文件。删除文件会从本机永久移除对应内容。
            """)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeedbackView: View {
    @Environment(AppModel.self) private var appModel
    @State private var message = ""
    @State private var sent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("告诉我们哪里需要改进")
                .font(.headline)
            TextEditor(text: $message)
                .frame(minHeight: 180)
                .padding(8)
                .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 16))
            PrimaryActionButton(title: sent ? "已发送" : "发送反馈", state: message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sent ? .disabled : .enabled) {
                sent = true
                appModel.transientMessage = "感谢你的反馈"
            }
            Text("反馈只会在你点击发送后交给系统邮件或反馈渠道处理。")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(24)
        .background(DesignTokens.Color.canvas)
        .navigationTitle("意见反馈")
        .navigationBarTitleDisplayMode(.inline)
    }
}

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 标题
                        VStack(spacing: 10) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 40))
                                .foregroundColor(ApocalypseTheme.primary)

                            Text("用户服务协议")
                                .font(.title.bold())
                                .foregroundColor(.white)

                            Text("Terms of Service")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        Divider()
                            .background(Color.white.opacity(0.2))

                        // 协议内容
                        VStack(alignment: .leading, spacing: 25) {
                            // 1. 接受条款
                            TermsSectionContent(
                                title: "1. 接受条款",
                                content: "欢迎使用《地球新主》（以下简称\"本应用\"）。使用本应用前，请仔细阅读本协议。一旦您使用本应用，即表示您已阅读、理解并同意本协议的所有条款。如果您不同意本协议的任何条款，请立即停止使用本应用。"
                            )

                            // 2. 服务说明
                            TermsSectionContent(
                                title: "2. 服务说明",
                                content: "本应用是一款基于GPS定位的LBS（Location-Based Service）生存游戏。玩家通过真实世界行走来圈占领地、探索资源、建造家园，并与其他玩家进行交易和社交。\n\n本服务包括但不限于以下功能：\n• GPS圈地系统\n• 探索与资源收集\n• 建造系统\n• 交易系统\n• 通讯系统\n• 行走奖励机制"
                            )

                            // 3. 用户注册与账号
                            TermsSectionContent(
                                title: "3. 用户注册与账号",
                                content: "3.1 注册资格\n您声明并保证您已年满18岁，或已获得法定监护人的同意使用本应用。\n\n3.2 账号安全\n• 您对自己的账号和密码的安全性负全部责任\n• 不得将账号转让、出借或分享给他人\n• 如发现账号被盗用，应立即通知我们\n• 因账号保管不善造成的损失由用户自行承担\n\n3.3 账号注销\n您有权随时注销账号，但需注意：\n• 注销将永久删除所有数据\n• 注销后无法恢复\n• 需先完成未完成的交易和订阅"
                            )

                            // 4. 用户行为规范
                            TermsSectionContent(
                                title: "4. 用户行为规范",
                                content: "在使用本应用时，您同意不：\n\n4.1 禁止行为\n• 使用作弊工具、外挂、脚本等\n• 利用漏洞或bug获取不当利益\n• 进行商业用途或转售服务\n• 干扰或破坏服务的正常运行\n• 侵犯他人权益或违反法律法规\n\n4.2 后果\n违反规范的账号将受到以下处罚：\n• 警告\n• 功能限制\n• 临时封禁\n• 永久封禁"
                            )

                            // 5. 知识产权
                            TermsSectionContent(
                                title: "5. 知识产权",
                                content: "本应用的所有内容，包括但不限于：\n• 软件代码\n• 图形、图标、界面设计\n• 音频、视频内容\n• 文字、数据\n\n均受知识产权法保护，归我们或我们的许可方所有。未经授权，您不得：\n• 复制、修改、分发\n• 用于商业目的\n• 反向工程或试图提取源代码"
                            )

                            // 6. 隐私保护
                            TermsSectionContent(
                                title: "6. 隐私保护",
                                content: "我们重视您的隐私。详细的隐私政策请参阅：\nhttps://liyanwena11.github.io/earthlord-support/privacy.html\n\n我们收集的信息包括：\n• 位置信息（用于GPS功能）\n• 设备信息\n• 使用数据\n• 账号信息"
                            )

                            // 7. 付费服务
                            TermsSectionContent(
                                title: "7. 付费服务",
                                content: "7.1 应用内购买\n本应用提供应用内购买功能，包括：\n• 订阅服务（探索者通行证、领主通行证）\n• 消耗型道具（补给包）\n\n7.2 退款政策\n• Apple的退款政策适用于所有购买\n• 订阅可随时取消，但不会 refund当期费用\n• 虚拟物品一旦购买，不予退款\n\n7.3 自动续费\n订阅服务默认开启自动续费，您可以在订阅到期前24小时关闭。"
                            )

                            // 8. 免责声明
                            TermsSectionContent(
                                title: "8. 免责声明",
                                content: "8.1 服务按\"现状\"提供\n本服务按\"现状\"和\"可用\"基础提供，不提供任何明示或暗示的保证。\n\n8.2 不可抗力\n对于因以下原因导致的服务中断或损失，我们不承担责任：\n• 不可抗力（如自然灾害、战争）\n• 政府行为或法律法规变化\n• 第三方服务故障（如Apple、Google服务）\n• 网络故障或技术问题\n\n8.3 第三方链接\n本应用可能包含第三方网站的链接。我们对这些网站的内容不承担责任。"
                            )

                            // 9. 服务变更与终止
                            TermsSectionContent(
                                title: "9. 服务变更与终止",
                                content: "9.1 服务变更\n我们保留随时修改或中断服务的权利，恕不另行通知。\n\n9.2 终止权\n在以下情况下，我们可能终止或暂停您的账号：\n• 违反本协议\n• 长期不活跃（超过6个月未登录）\n• 提供虚假信息\n• 从事违法或欺诈活动"
                            )

                            // 10. 争议解决
                            TermsSectionContent(
                                title: "10. 争议解决",
                                content: "10.1 适用法律\n本协议受中华人民共和国法律管辖。\n\n10.2 争议解决\n因本协议引起的任何争议，双方应首先通过友好协商解决。协商不成的，任何一方可向我们所在地人民法院提起诉讼。\n\n10.3 可分割性\n如本协议的任何条款被认定为无效或不可执行，其余条款仍然有效。"
                            )

                            // 11. 协议更新
                            TermsSectionContent(
                                title: "11. 协议更新",
                                content: "我们保留随时修改本协议的权利。修改后的协议将在应用内公布。继续使用本应用即表示您接受修改后的协议。\n\n重大变更将通过以下方式通知：\n• 应用内通知\n• 邮件通知\n• 官网公告"
                            )

                            // 12. 联系我们
                            TermsSectionContent(
                                title: "12. 联系我们",
                                content: "如您对本协议有任何疑问，请通过以下方式联系我们：\n\n• 官网：https://liyanwena11.github.io/earthlord-support/\n• 邮箱：support@earthlord.game\n• 在应用内：设置 → 帮助中心 → 联系客服"
                            )

                            // 底部信息
                            VStack(spacing: 10) {
                                Text("最后更新：2025年3月")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))

                                Text("本协议为中英文双语版本，如有冲突，以中文版本为准。")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)

                        }
                        .padding(.horizontal)
                        .padding(.bottom, 50)
                    }
                }
            }
            .navigationTitle("用户协议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TermsSectionContent: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(ApocalypseTheme.primary)

            Text(content)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(5)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(ApocalypseTheme.primary.opacity(0.2), lineWidth: 1))
    }
}

#Preview {
    TermsOfServiceView()
}

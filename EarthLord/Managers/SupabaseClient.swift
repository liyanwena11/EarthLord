//
//  SupabaseClient.swift
//  EarthLord
//
//  Created by lyanwen on 2025/12/31.
//

import Foundation
import Supabase

/// Supabase 客户端单例
/// 全局唯一的 Supabase 客户端实例，用于所有后端交互
let supabaseClient = SupabaseClient(
    supabaseURL: URL(string: "https://lkekxzssfrspkyxtqysx.supabase.co")!,
    supabaseKey: "sb_publishable_8Gg8z5XRTOkupYVm6MbACg_Lc9CXU4I"
)

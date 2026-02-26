//
//  StringExtensions.swift
//  EarthLord
//
//  String 扩展方法
//

import Foundation

extension String {
    /// 在字符串中查找所有匹配正则表达式的子串
    /// - Parameter pattern: 正则表达式模式
    /// - Returns: 匹配的字符串数组
    func findMatches(pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(location: 0, length: self.utf16.count)
        let matches = regex.matches(in: self, range: range)

        return matches.compactMap {
            if let range = Range($0.range, in: self) {
                return String(self[range])
            }
            return nil
        }
    }
}

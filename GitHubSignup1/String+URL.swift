//
//  String+URL.swift
//  GitHubSignup1
//
//  Created by 藤門莉生 on 2023/02/11.
//

import Foundation

extension String {
    var URLEscaped: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
    }
}

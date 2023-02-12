//
//  DefaultImplementations.swift
//  GitHubSignup1
//
//  Created by 藤門莉生 on 2023/02/11.
//

import RxSwift
import Foundation

class GitHubDefaultAPI: GitHubAPI {
    let URLSession: Foundation.URLSession
   
    static let sharedAPI = GitHubDefaultAPI(
        URLSession: Foundation.URLSession.shared
    )
    
    init(URLSession: Foundation.URLSession) {
        self.URLSession = URLSession
    }
    
    func usernameAvailable(_ username: String) -> Observable<Bool> {
        // this is ofc just mock, but good enough
        /*
         "https://github.com/\(ユーザ名)"としてリクエストした結果、
         ステータスコード404がが返ってくるかどうかをチェックしている
         */
        let url = URL(string: "https://github.com/\(username.URLEscaped)")!
        let request = URLRequest(url: url)
        return self.URLSession.rx.response(request: request)
            .map { pair in
                return pair.response.statusCode == 404
            }
            .catchAndReturn(false)
        
    }
    
    func signup(_ username: String, password: String) -> Observable<Bool> {
        // this is also just a mock
        let signupResult = arc4random() % 5 == 0 ? false : true
        
        return Observable
            .just(signupResult)
            .delay(.seconds(1), scheduler: MainScheduler.instance)
    }
}

class GitHubDefaultValidationService: GitHubValidationService {
    let API: GitHubAPI
    
    static let sharedValidationService = GitHubDefaultValidationService(API: GitHubDefaultAPI.sharedAPI)
    
    init(API: GitHubAPI) {
        self.API = API
    }
    
    // validation
    let minPasswordCount = 5
    
    func validateUsername(_ username: String) -> Observable<ValidationResult> {
        if username.isEmpty {
            return .just(.empty)
        }
        
        // this obviously won't be
        if username.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil {
            return .just(.failed(message: "Username can only contain numbers or digits"))
        }
        
        let loadingValue = ValidationResult.validating
       
        /*
         ステータスコードが404になった場合には、ユーザが存在しないため、
         サインアップ用のユーザ名として問題ないために
         ValidationResult.ok(message: String)としている。
         普段ならエラーに対するステータスコード404を正常とする処理に混乱しそうなところだが、
         このサンプルでは正しいやり方である。
         */
        return API
            .usernameAvailable(username)
            .map { available in
                if available {
                    return .ok(message: "Username available")
                }
                else {
                    return .failed(message: "Username already taken")
                }
            }
            .startWith(loadingValue)
    }
    
    func validatePassword(_ password: String) -> ValidationResult {
        let numberOfCharacters = password.count
        if numberOfCharacters == 0 {
            return .empty
        }
        
        if numberOfCharacters < minPasswordCount {
            return .failed(message: "Password must be at least \(minPasswordCount) characters")
        }
        
        return .ok(message: "Password acceptable")
    }
    
    /*
     validateRepeatedPasswordは、
     passwordとrepeatedPasswordが
     同じかを比較し、ValidationResultにして返す。
     入力されたパスワードに関する2つのストリームから文字列を取り出して比較し、
     それぞれの文字列が同じならValidationResult.ok(message: String)を
     持つストリームを返す
     */
    func validateRepeatedPassword(_ password: String, repeatedPassword: String) -> ValidationResult {
        if repeatedPassword.count == 0 {
            return .empty
        }
        
        if repeatedPassword == password {
            return .ok(message: "Password repeated")
        }
        else {
            return .failed(message: "password different")
        }
    }
    
}

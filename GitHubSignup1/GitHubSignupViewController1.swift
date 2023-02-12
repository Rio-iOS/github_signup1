//
//  ViewController.swift
//  GitHubSignup1
//
//  Created by 藤門莉生 on 2023/02/11.
//

import UIKit
import RxSwift
import RxCocoa

class GitHubSignupViewController1: UIViewController {

    var disposeBag = DisposeBag()
    // ViewControllerの実装1
    // IBOutletをViewControllerに接続
    @IBOutlet weak var usernameOutlet: UITextField!
    @IBOutlet weak var usernameValidationOutlet: UILabel!
    
    @IBOutlet weak var passwordOutlet: UITextField!
    @IBOutlet weak var passwordValidationOutlet: UILabel!
    
    @IBOutlet weak var repeatedPasswordOutlet: UITextField!
    @IBOutlet weak var repeatedPasswordValidationOutlet: UILabel!
    
    @IBOutlet weak var signupOutlet: UIButton!
    @IBOutlet weak var signingUpOutlet: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // ViewControllerの実装2. ViewModelの初期化
        let viewModel = GithubSignupViewModel1(
            input:(
                // ViewControllerの実装2_1
                username: usernameOutlet.rx.text.orEmpty.asObservable(),
                password: passwordOutlet.rx.text.orEmpty.asObservable(),
                repeatedPassword: repeatedPasswordOutlet.rx.text.orEmpty.asObservable(),
                loginTaps: signupOutlet.rx.tap.asObservable()
            ),
            dependency: (
                API: GitHubDefaultAPI.sharedAPI,
                validationService: GitHubDefaultValidationService.sharedValidationService,
                wireframe: DefaultWireframe.shared
            )
        )
        
        // ViewControllerの実装3. ViewModelのアウトプットからViewにbind
        // ViewControllerの実装3_1
        viewModel.signupEnabled
            .subscribe { [weak self] valid in
                self?.signupOutlet.isEnabled = valid
                self?.signupOutlet.alpha = valid ? 1.0 : 0.5
            }
            .disposed(by: disposeBag)
        
        // ViewControllerの実装3_2
        viewModel.validatedUsername
            .bind(to: usernameValidationOutlet.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.validatedPassword
            .bind(to: passwordValidationOutlet.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.validatedPasswordRepeated
            .bind(to: repeatedPasswordValidationOutlet.rx.validationResult)
            .disposed(by: disposeBag)
        
        viewModel.signedIn
            .subscribe { signedIn in
                print("User signed in (signedIn)")
            }
            .disposed(by: disposeBag)
        
        // ViewControllerの実装4. 画面をタップされるジェスチャーを設定
        // 入力モードを終了しソフトウェアキーボードを閉じる
        let tapBackground = UITapGestureRecognizer()
        tapBackground.rx.event
            .subscribe { [weak self] _ in
                self?.view.endEditing(true)
            }
            .disposed(by: disposeBag)
        view.addGestureRecognizer(tapBackground)
    }


}


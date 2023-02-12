//
//  GithubSignupViewModel.swift
//  GitHubSignup1
//
//  Created by 藤門莉生 on 2023/02/11.
//

import RxSwift
import RxCocoa

class GithubSignupViewModel1 {
    let validatedUsername: Observable<ValidationResult>
    let validatedPassword: Observable<ValidationResult>
    let validatedPasswordRepeated: Observable<ValidationResult>
    
    // Is signup button enabled
    let signupEnabled: Observable<Bool>
    
    // Has user signed in
    let signedIn: Observable<Bool>
    
    // Is signing process in progress
    let signingIn: Observable<Bool>
    
    init(
        input: (
            username: Observable<String>,
            password: Observable<String>,
            repeatedPassword: Observable<String>,
            loginTaps: Observable<Void>
        ),
        dependency: (
            API: GitHubAPI,
            validationService: GitHubValidationService,
            wireframe: Wireframe
        )
    ) {
        let API = dependency.API
        let validationService = dependency.validationService
        let wireframe = dependency.wireframe
        
        // ViewModelの実装2：イニシャライザでObservableをsubscribeせず出力へ変換している
        // 実装2_2
        /*
         パスワードのバリデートは単に文字列の数をチェックするだけだが、
         ユーザ名については実際のGitHubに通信してその結果を利用する。
         
         1. validationService.validateUsernameメソッドにより、
         　　入力されたユーザ名に対して通信した結果をObservable<ValidationResult>とする。
         
         2. その結果の処理にメインスレッドを指定している
         
         3. もしバリデート時にエラーが発生したらValidationResult.faild(message: String)に差し替える
         
         【flatMapLatestの特徴】
         最新のイベントを伝達することを目的としているため、
         既に実行済みの最新でないイベントを破棄する特徴がある。
         バリデート用のHTTPS通信を順次行なっている今回の場合だと、
         その連続した処理が実行されるたびに、古いリクエストはレスポンスを受け取る前に終了する。
         
         注意する点として、flatMapLatest自体で作成したストリームの結果を重複して
         待ち受けずに済むという意味で無駄を省けるのであって、
         通信を実行すること自体の無駄はflatMapLatestでは省けていない
         
         [ex]
         RESTFullなWeb APIにより、リソースをサーバ上に作成するような通信を行う場合、
         flatMapLatestでdisposeされる前にサーバ上へリクエストが到達し、
         リソース作成が完了してしまうというような場合の無駄は省けない
         */
        validatedUsername = input.username
            .flatMapLatest({ usernmae in
                return validationService.validateUsername(usernmae)
                    .observe(on: MainScheduler.instance)
                    .catchAndReturn(.failed(message: "Error contacting server"))
            })
            .share(replay: 1)
        
        // ViewModelの実装2_1
        /*
         Observableを変換するmap
         動作としては、ユーザにより入力されるパスワードの文字列の
         イベントinput.password: Observable<String>からmapオペレータにより
         文字列を取り出し処理を適用する。
         mapオペレータの処理は、バリデートを行う
         validationService.validatePassword(password)メソッドを実行し、
         その結果をValidationResultのストリームに変換される。
         バリデートに問題がなければValidationResult.ok(message: String)とし、
         その際の表示メッセージもデータとして含ませている。
         
         メソッドチェインにより最後に適用されているshare(replay: 1)は、
         Cold ObservableをHot Observableへ変換するためのオペレータ
         */
        
        /*
         share(replay: 1)によるHot変換
         Hot Observableへ変換するためのオペレータの必要性を理解するために、share(replay: 1)をコメントアウトすることで、その結果から振る舞いがわかる
         
         share(replay: 1)をコメントアウトすると、mapオペレータの動作は複数になる
         */
        // share(replay: 1)のテスト
        /*
         .share(replay: 1)がないと、
         mapという出力が1つから2つに増える
         これが、share(replay: 1)を使っていた理由である。
         購読されている回数分動作してしまう
         
         購読されるたびに動作してしまうのを避けるための変換は、Cold ObservableからHot Obsrevableへの変換と呼ぶ
         
         もともとControlPropertyは、Hot Observableであり、
         rx.text.orEmpty.asObservableによって得られたinput.password: Observable<String>についてもHot Observable
         
         そのため、input.password: Observable<String>自体の処理は共有されており、
         もともとユーザ入力自体が複数になることはない
         
         ViewModelの出力は、複数購読された場合を想定し、
         あらかじめshare(replay: 1)によりHot変換してくれている
         
         ストリームはViewModel外部から見たさいに、Hot Obsrvableかそうでないかの区別が
         つかないので、出力変換時にあらかじめHot変換を行うことは現実的で合理的なやり方
         */
        /*
        let o: Observable<ValidationResult> = input.password
            .map { password in
                print("map:")
                return validationService.validatePassword(password)
            }
            // .share(replay: 1)
        
        _ = o.subscribe(onNext: {_ in
            print("onNext: s1")
        })
        
        _ = o.subscribe(onNext: { _ in
            print("onNext: s2")
        })
         */
        
        
        validatedPassword = input.password
            .map({ password in
                return validationService.validatePassword(password)
            })
            .share(replay: 1)
        
        // ViewModelの実装2_3
        /*
         Observableを合成するcombineLatest
         入力されたパスワード文字列のストリームinput.passwordと
         パスワード確認文字列のストリームinput.repeatedPasswordを
         combineLatestオペレータを使って合成する実装
         
         combineLatestは引数により2つの入力を受け取り、
         引数resultSelectorにより、合成する処理方法を受け取ることができるオペレータ
         resultSelectorに渡しているvalidationService.validateRepeatedPasswordは、
         DefaultImplementations.swiftにて、passwordとrepeatedPasswordが
         同じかを比較し、ValidationResultにして返す。
         */
        validatedPasswordRepeated = Observable.combineLatest(
            input.password,
            input.repeatedPassword,
            resultSelector: validationService.validateRepeatedPassword
        )
        .share(replay: 1)
        
        let signingIn = ActivityIndicator()
        self.signingIn = signingIn.asObservable()
        
        // ViewModelの実装2_4
        /*
         combineLatestはクロージャを渡し、コードを書くこともできる
         ユーザ名のストリームinput.usernameとパスワード入力のストリームinput.passwordに
         ついて、combineLatestでクロージャによって合成方法を指定している。
         
         クロージャの処理内容としては、引数にとる2つのストリームの文字列をタプルとして作成し、
         ユーザ名の文字列とパスワードの文字列を1つの
         usernameAndPassword: Observable<(username: String, password: String)>ストリームとしている。
         複数ストリームを合成したストリームにすることは、データをまとめて利便性を上げることもできる
         
         */
        let usernameAndPassword = Observable.combineLatest(
            input.username,
            input.password
        ) {
            (username: $0, password: $1)
        }
        
        // ViewModelの実装2_5
        /*
         最新の値を取得するwithLatestFrom
         サインアップボタンのイベントを伝達するloginTaps: Observable<Void>ストリームに
         よって、withLatestFromオペレータでその最新のデータを取得される
         
         すなわち、ボタンを押されたタイミングをきっかけに、ユーザ名とパスワードの文字列を使って
         当初の目的であったサインアップ処理を行うイベントを作成したい
         
         withLatestFromオペレータは、元となるloginTaps: Observable<Void>の
         イベントに応じて、新たなストリームのイベントへと合成する
         
         この一連の流れでは、バリデート済みユーザ名とパスワードの文字列からGitHubサインアップを行い、その結果をwireframe.promptForメソッドにより表示させている。
         
         それと同時に、その表示を行う際に、
         ViewModelのプロパティsignedIn: Observable<Bool>ストリームへ
         その結果を出力もしており、ViewControllerは、このストリームをバインドすることで
         結果をViewに反映する。
         */
        signedIn = input.loginTaps.withLatestFrom(usernameAndPassword)
            .flatMapLatest { pair in
                return API.signup(pair.username, password: pair.password)
                    .observe(on: MainScheduler.instance)
                    .catchAndReturn(false)
                    .trackActivity(signingIn)
            }
            .flatMapLatest { loggedIn -> Observable<Bool> in
                let message = loggedIn ? "Mock: Signed in to GitHub." : "Mock: Sign in to GitHub failed"
                
                return wireframe.promptFor(
                    message,
                    cancelAction: "OK",
                    actions: []
                )
                .map { _ in
                    loggedIn
                }
            }
            .share(replay: 1)
        
        signupEnabled = Observable.combineLatest(
            validatedUsername,
            validatedPassword,
            validatedPasswordRepeated,
            signingIn.asObservable()
        ) { username, passweord, repeatPassword, signingIn in
            username.isValid &&
            passweord.isValid &&
            repeatPassword.isValid &&
            !signingIn
        }
        .distinctUntilChanged()
        .share(replay: 1)
    }
}

/*
* JBoss, Home of Professional Open Source.
* Copyright Red Hat, Inc., and individual contributors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import UIKit
import XCTest
import TDConnectIosSdk
import AeroGearHttp
import OHHTTPStubs

class OpenIDConnectGoogleOAuth2ModuleTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    class MyMockOAuth2ModuleSuccess: OAuth2Module {

        override func requestAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
            let accessToken: AnyObject? = NSString(string:"TOKEN")
            completionHandler(accessToken, nil)
        }
    }

    class MyMockOAuth2ModuleFailure: OAuth2Module {

        override func requestAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
            completionHandler(nil, NSError(domain: "", code: 0, userInfo: nil))
        }
    }

    func testGoogleOpenIDSuccess() {
        let loginExpectation = expectation(description: "Login")

        let googleConfig = GoogleConfig(
            clientId: "xxxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"],
            isOpenIDConnect: true)

        // set up http stub
        setupStubWithNSURLSessionDefaultConfiguration()
        let oauth2Module = AccountManager.addAccountWith(config: googleConfig, moduleClass: MyMockOAuth2ModuleSuccess.self)

        oauth2Module.login {(accessToken: AnyObject?, claims: OpenIdClaim?, error: NSError?) in

            XCTAssertTrue("John" == claims?.name, "claim should be as mocked")
            loginExpectation.fulfill()

        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testGoogleOpenIDFailureNoUserInfoEndPoint() {
        let loginExpectation = expectation(description: "Login")

        let googleConfig = Config(base: "https://accounts.google.com",
            authzEndpoint: "o/oauth2/auth",
            redirectURL: "google:/oauth2Callback",
            accessTokenEndpoint: "o/oauth2/token",
            clientId: "xxxx.apps.googleusercontent.com",
            refreshTokenEndpoint: "o/oauth2/token",
            revokeTokenEndpoint: "rest/revoke",
            isOpenIDConnect: true,
            userInfoEndpoint: nil,
            scopes: ["openid", "email", "profile"],
            accountId: "acc")
        // set up http stub
        setupStubWithNSURLSessionDefaultConfiguration()
        let oauth2Module = AccountManager.addAccountWith(config: googleConfig, moduleClass: MyMockOAuth2ModuleSuccess.self)

        oauth2Module.login {(accessToken: AnyObject?, claims: OpenIdClaim?, error: NSError?) in
            var erroDict = (error?.userInfo)!
            let value = erroDict["OpenID Connect"] as! String
            XCTAssertTrue( value == "No UserInfo endpoint available in config", "claim should be as mocked")
            loginExpectation.fulfill()

        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testGoogleOpenIDFailure() {
        let loginExpectation = expectation(description: "Login")

        let googleConfig = GoogleConfig(
            clientId: "xxx.apps.googleusercontent.com",
            scopes:["https://www.googleapis.com/auth/drive"],
            isOpenIDConnect: true)


        let oauth2Module = AccountManager.addAccountWith(config: googleConfig, moduleClass: MyMockOAuth2ModuleFailure.self)

        oauth2Module.login {(accessToken: AnyObject?, claims: OpenIdClaim?, error: NSError?) in

            XCTAssertTrue(error != nil, "Error")
            loginExpectation.fulfill()

        }
        waitForExpectations(timeout: 10, handler: nil)
    }

}

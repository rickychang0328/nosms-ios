
import XCTest
import OneTimePassword
@testable import NoSMS

class NoSMSTokenURLTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        if let url = URL(string: "mustauth://totp/google:Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "google")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            
        } else {
            
            XCTFail()
        }
        
        if let url = URL(string: "mustauth://totp/google%3A%20%20%20%20%20%20Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "google")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            
        } else {
            
            XCTFail()
        }
        
        if let url = URL(string: "mustauth://totp/go%20ogle%3A%20%20%20%20%20%20Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "go ogle")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/google:Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=google") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "google")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/:Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=google") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "google")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/error:Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=google") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "google")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=google") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "google")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/Levi@:gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=google") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "google")
            XCTAssertEqual(token.name, "gmail.com")
            
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/:Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/google:Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/google:Levi:@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=google") {
            
            let token = Token(customURL: url)
            
            XCTAssertNil(token)
        } else {
            
            XCTFail()
        }
        
        if let url = URL(string: "mustauth://totp/google:Levi:@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=google&issuer=google") {
            
            let token = Token(customURL: url)
            
            XCTAssertNil(token)
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/google%3ALevi%3A@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=google") {
            
            let token = Token(customURL: url)
            
            XCTAssertNil(token)
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/google:Levi:@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ") {
            
            let token = Token(customURL: url)
            
            XCTAssertNil(token)
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/google:Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=goo:gle") {
            
            let token = Token(customURL: url)
            
            XCTAssertNil(token)
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/google:Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=goo%3Agle") {
            
            let token = Token(customURL: url)
            
            XCTAssertNil(token)
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/::Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=") {
            
            let token = Token(customURL: url)
            
            XCTAssertNil(token)
        } else {
            
            XCTFail()
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

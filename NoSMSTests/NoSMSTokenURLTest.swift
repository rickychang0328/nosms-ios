
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
        if let url = URL(string: "otpauth://totp/prod%3Axnb.fenko%3Abuoucheck01?secret=MFRGCNRWMU3WMLLCMU4GMLJUMFTGMLJYMU3GMLLGHEYDONLFGY3WGMBUHE") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "")
            XCTAssertEqual(token.name, "prod:xnb.fenko:buoucheck01")
            
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "prod:xnb.fenko:buoucheck01")
            XCTAssertEqual(mustAuth.issuer, "")
            
        } else {
            
            XCTFail()
            return
        }
        if let url = URL(string: "mustauth://totp/google:Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "google")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "google")
            
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
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
           
            XCTAssertEqual(mustAuth.name, "Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "google")
            
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
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "go ogle")
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
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "google")
            
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
            
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "google")
            
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
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "google")
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
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "google")
            
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
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "gmail.com")
            XCTAssertEqual(mustAuth.issuer, "google")
            
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
            
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "")
            
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
            
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "")
            
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
            
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "")
            
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
            
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "")
            
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/google:Levi:@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=google") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "google")
            XCTAssertEqual(token.name, "google:Levi:@gmail.com")
            
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "google:Levi:@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "google")
        } else {
            
            XCTFail()
        }
        
        if let url = URL(string: "mustauth://totp/google:Levi:@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=google&issuer=google") {
            
            let token = Token(customURL: url)
            
            XCTAssertNil(token)
            let mustauth = try? url.mustAuth.parsingSetURL()
            XCTAssertNil(mustauth)
        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/google%3ALevi%3A@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=google") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "google")
            XCTAssertEqual(token.name, "google:Levi:@gmail.com")
            
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "google:Levi:@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "google")

        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/google:Levi:@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "")
            XCTAssertEqual(token.name, "google:Levi:@gmail.com")
            
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "google:Levi:@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "")

        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/google:Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=goo:gle") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "goo:gle")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "goo:gle")

        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/google:Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=goo%3Agle") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "goo:gle")
            XCTAssertEqual(token.name, "Levi@gmail.com")
            
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "goo:gle")

        } else {
            
            XCTFail()
        }
        if let url = URL(string: "mustauth://totp/::Levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=") {
            
            guard let token = Token(customURL: url) else {
                
                XCTFail()
                return
            }
            
            XCTAssertEqual(token.issuer, "")
            XCTAssertEqual(token.name, "::Levi@gmail.com")
            
            guard let mustAuth = try? url.mustAuth.parsingSetURL() else {
                    
                XCTFail()
                return
            }
            
            XCTAssertEqual(mustAuth.name, "::Levi@gmail.com")
            XCTAssertEqual(mustAuth.issuer, "")

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

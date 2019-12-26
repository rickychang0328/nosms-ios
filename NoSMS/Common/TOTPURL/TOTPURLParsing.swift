
import OneTimePassword
import Base32
import Foundation

private let defaultAlgorithm: Generator.Algorithm = .sha1
private let defaultDigits: Int = 6
private let defaultCounter: UInt64 = 0
private let defaultPeriod: TimeInterval = 30

private let kQueryAlgorithmKey = "algorithm"
private let kQuerySecretKey = "secret"
private let kQueryCounterKey = "counter"
private let kQueryDigitsKey = "digits"
private let kQueryPeriodKey = "period"
private let kQueryIssuerKey = "issuer"
private let kFactorCounterKey = "hotp"
private let kFactorTimerKey = "totp"

private let kAlgorithmSHA1   = "SHA1"
private let kAlgorithmSHA256 = "SHA256"
private let kAlgorithmSHA512 = "SHA512"

enum SerializationError: Error {
    
    case urlGenerationFailure
}

enum DeserializationError: Error {
    case invalidURLScheme
    case duplicateQueryItem(String)
    case missingFactor
    case invalidFactor(String)
    case invalidCounterValue(String)
    case invalidTimerPeriod(String)
    case missingSecret
    case invalidSecret(String)
    case invalidAlgorithm(String)
    case invalidDigits(String)
    case actionError
}

struct MustAuth {
    
    static let kQueryActionKey = "action"
    static let kQueryActionGetValue = "get"
    static let kQueryActionSetValue = "set"
    static let kMustAuthScheme = "mustauth"
    static let kOTPAuthScheme = "otpauth"

    
    enum ActionEnum {
        
        case get
        case set
        
        init?(string: String) {
            
            switch string {
            case kQueryActionGetValue:
                
                self = .get
            case kQueryActionSetValue:
                
                self = .set
                
            default:
                
                return nil
            }
        }
    }
    
    struct URLParsing {
    
        let action: ActionEnum
        
        let name: String
        
        let issuer: String
        
        let factor: Generator.Factor
        
        let secretString: String
        
        let algorithm: Generator.Algorithm
        
        let digits: Int
        
        let secretData: Data
        
        let url: URL
        
        init(_ value: String) throws {
            
            let stringURL = value.trimmingCharacters(in: .whitespaces)
                                
            guard let url = URL(string: stringURL) else {
                
                throw SerializationError.urlGenerationFailure
            }
            
            guard url.scheme == kOTPAuthScheme || url.scheme == kMustAuthScheme else {
                throw DeserializationError.invalidURLScheme
            }

            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

            let factor: Generator.Factor
            switch url.host {
            case .some(kFactorCounterKey):
                let counterValue = try queryItems.value(for: kQueryCounterKey).map(parseCounterValue) ?? defaultCounter
                factor = .counter(counterValue)
            case .some(kFactorTimerKey):
                let period = try queryItems.value(for: kQueryPeriodKey).map(parseTimerPeriod) ?? defaultPeriod
                factor = .timer(period: period)
            case let .some(rawValue):
                throw DeserializationError.invalidFactor(rawValue)
            case .none:
                throw DeserializationError.missingFactor
            }

            let algorithm = try queryItems.value(for: kQueryAlgorithmKey).map(algorithmFromString) ?? defaultAlgorithm
            let digits = try queryItems.value(for: kQueryDigitsKey).map(parseDigits) ?? defaultDigits
            
            guard let secretString = try queryItems.value(for: kQuerySecretKey) else {
                
                throw DeserializationError.missingSecret
            }
            
            if secretString.isEmpty {
                
                throw DeserializationError.missingSecret
            }
            
            guard let secret = try queryItems.value(for: kQuerySecretKey).map(parseSecret) else {
                throw DeserializationError.missingSecret
            }
            
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                
                throw SerializationError.urlGenerationFailure
            }
            
            let action: ActionEnum
            
            if let actionQuery = urlComponents.queryItems?.firstIndex(where: {$0.name == kQueryActionKey}) {
                
                guard let actionString = urlComponents.queryItems?[actionQuery].value,
                    let actionEnum = ActionEnum(string: actionString) else {
                        
                    throw  DeserializationError.actionError
                }
                urlComponents.queryItems?.remove(at: actionQuery)
                action = actionEnum
                
            } else {
                
                action = .set
            }
            
            guard let newURL = urlComponents.url else {
                
                throw SerializationError.urlGenerationFailure
            }
               // Skip the leading "/"
            
            guard !url.path.isEmpty else {
                
                throw SerializationError.urlGenerationFailure
            }
            let fullName = String(url.path.dropFirst())

            let issuer: String
            if let issuerString = try queryItems.value(for: kQueryIssuerKey) {
                issuer = issuerString
            } else if let separatorRange = fullName.range(of: ":") {
                // If there is no issuer string, try to extract one from the name
                issuer = String(fullName[..<separatorRange.lowerBound])
            } else {
                // The default value is an empty string
                throw SerializationError.urlGenerationFailure
            }
            
            if issuer.trimmingCharacters(in: .whitespaces).isEmpty {
                
                throw SerializationError.urlGenerationFailure
            }
            
            let name = shortName(byTrimming: issuer, from: fullName)
            
            self.name = name
            self.issuer = issuer
            self.algorithm = algorithm
            self.digits = digits
            self.factor = factor
            self.secretString = secretString
            self.secretData = secret
            self.url = newURL
            self.action = action
        }
    }
    
    let value: String
    
    init(_ value: String) {
        
        self.value = value
    }
    
    func urlSetParsing() throws -> URLParsing {
        
        return try URLParsing(value)
    }
    
    func secretStringToData() throws -> Data {
        
        return try parseSecret(value)
    }
    
    func parsingGetURL() throws -> ParsingGetURL {
        
        return try ParsingGetURL(value: value)
    }
    
    struct ParsingGetURL {
        
        let name: String
        let issuer: String
        
        init(value: String) throws {
            
            let stringURL = value.trimmingCharacters(in: .whitespaces)
                                
            guard let url = URL(string: stringURL) else {
                
                throw SerializationError.urlGenerationFailure
            }
            
            guard url.scheme == kOTPAuthScheme || url.scheme == kMustAuthScheme else {
                throw DeserializationError.invalidURLScheme
            }

            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

            guard !url.path.isEmpty else {
                
                throw SerializationError.urlGenerationFailure
            }
            let fullName = String(url.path.dropFirst())

            let issuer: String
            if let issuerString = try queryItems.value(for: kQueryIssuerKey) {
                issuer = issuerString
            } else if let separatorRange = fullName.range(of: ":") {
                // If there is no issuer string, try to extract one from the name
                issuer = String(fullName[..<separatorRange.lowerBound])
            } else {
                // The default value is an empty string
                throw SerializationError.urlGenerationFailure
            }
            
            let name = shortName(byTrimming: issuer, from: fullName)
            
            self.name = name
            self.issuer = issuer
        }
    }
}

private func parseCounterValue(_ rawValue: String) throws -> UInt64 {
    
    guard let counterValue = UInt64(rawValue) else {
        throw DeserializationError.invalidCounterValue(rawValue)
    }
    return counterValue
}

private func parseTimerPeriod(_ rawValue: String) throws -> TimeInterval {
    guard let period = TimeInterval(rawValue) else {
        throw DeserializationError.invalidTimerPeriod(rawValue)
    }
    return period
}

private func parseSecret(_ rawValue: String) throws -> Data {
    guard let secret = MF_Base32Codec.data(fromBase32String: rawValue) else {
        throw DeserializationError.invalidSecret(rawValue)
    }
    return secret
}

private func parseDigits(_ rawValue: String) throws -> Int {
    guard let digits = Int(rawValue) else {
        throw DeserializationError.invalidDigits(rawValue)
    }
    return digits
}

extension Array where Element == URLQueryItem {
    
    func value(for name: String) throws -> String? {
        let matchingQueryItems = self.filter({
            $0.name == name
        })
        guard matchingQueryItems.count <= 1 else {
            throw DeserializationError.duplicateQueryItem(name)
        }
        return matchingQueryItems.first?.value
    }
}

private func stringForAlgorithm(_ algorithm: Generator.Algorithm) -> String {
    switch algorithm {
    case .sha1:
        return kAlgorithmSHA1
    case .sha256:
        return kAlgorithmSHA256
    case .sha512:
        return kAlgorithmSHA512
    }
}

private func shortName(byTrimming issuer: String, from fullName: String) -> String {
    if !issuer.isEmpty {
        let prefix = issuer + ":"
        if fullName.hasPrefix(prefix), let prefixRange = fullName.range(of: prefix) {
            let substringAfterSeparator = fullName[prefixRange.upperBound...]
            return substringAfterSeparator.trimmingCharacters(in: CharacterSet.whitespaces)
        }
    }
    return String(fullName)
}

private func algorithmFromString(_ string: String) throws -> Generator.Algorithm {
    switch string {
    case kAlgorithmSHA1:
        return .sha1
    case kAlgorithmSHA256:
        return .sha256
    case kAlgorithmSHA512:
        return .sha512
    default:
        throw DeserializationError.invalidAlgorithm(string)
    }
}


extension String {
    
    var mustAuth: MustAuth {
        
        MustAuth(self)
    }
}

extension URL {
    
    var mustAuth: MustAuth {
        
        MustAuth(self.absoluteString)
    }
}

extension Token {
    
    init?(customURL: URL) {
        
        guard var urlComp = URLComponents(url: customURL, resolvingAgainstBaseURL: false) else {
            
            return nil
        }
        
        if urlComp.scheme == MustAuth.kMustAuthScheme {
            
            urlComp.scheme = MustAuth.kOTPAuthScheme
        }
        
        let queryItems = urlComp.queryItems ?? []
        
        guard let secretString = try? queryItems.value(for: kQuerySecretKey) else {
            
            return nil
        }
        
        if secretString.isEmpty {
            
            return nil
        }
        
        guard let url = urlComp.url else {
            
            return nil
        }
        
        guard let token = Token(url: url) else {
            
            return nil
        }
        
        self = token
    }
}

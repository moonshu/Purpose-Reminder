import Foundation
import FamilyControls
import ManagedSettings

enum PolicyTargetToken {
    case application(ApplicationToken)
    case category(ActivityCategoryToken)
    case webDomain(WebDomainToken)
}

enum PolicyTargetTokenCodecError: LocalizedError {
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "정책 토큰 인코딩에 실패했습니다."
        case .decodingFailed:
            return "정책 토큰 디코딩에 실패했습니다."
        }
    }
}

struct PolicyTargetTokenCodec {
    private enum Kind: String, Codable {
        case application
        case category
        case webDomain
    }

    private struct Envelope: Codable {
        let kind: Kind
        let tokenData: Data
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func encode(_ target: PolicyTargetToken) throws -> Data {
        do {
            let envelope: Envelope

            switch target {
            case .application(let token):
                envelope = Envelope(kind: .application, tokenData: try encoder.encode(token))
            case .category(let token):
                envelope = Envelope(kind: .category, tokenData: try encoder.encode(token))
            case .webDomain(let token):
                envelope = Envelope(kind: .webDomain, tokenData: try encoder.encode(token))
            }

            return try encoder.encode(envelope)
        } catch {
            throw PolicyTargetTokenCodecError.encodingFailed
        }
    }

    func decode(from data: Data) throws -> PolicyTargetToken {
        if let envelope = try? decoder.decode(Envelope.self, from: data) {
            do {
                switch envelope.kind {
                case .application:
                    return .application(try decoder.decode(ApplicationToken.self, from: envelope.tokenData))
                case .category:
                    return .category(try decoder.decode(ActivityCategoryToken.self, from: envelope.tokenData))
                case .webDomain:
                    return .webDomain(try decoder.decode(WebDomainToken.self, from: envelope.tokenData))
                }
            } catch {
                throw PolicyTargetTokenCodecError.decodingFailed
            }
        }

        // Backward compatibility: older policies saved raw ApplicationToken JSON data.
        if let token = try? decoder.decode(ApplicationToken.self, from: data) {
            return .application(token)
        }

        throw PolicyTargetTokenCodecError.decodingFailed
    }
}

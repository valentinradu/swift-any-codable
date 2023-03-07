//
//  AnyCodable.swift
//
//
//  Created by Valentin Radu on 03/03/2023.
//

import Foundation

private class MemoizedThrowingBox<V> {
    private var _value: V?
    private let _provider: () throws -> V

    init(_ provider: @escaping () throws -> V) {
        _provider = provider
    }

    func fetchValue() throws -> V {
        if let value = _value {
            return value
        } else {
            let value = try _provider()
            _value = value
            return value
        }
    }
}

public struct AnyCodable: Codable, @unchecked Sendable {
    enum CodingKeys: CodingKey {
        case mangledTypeName
        case baseData
    }

    public let base: Any
    private let _mangledTypeName: String
    private var _baseDataBox: MemoizedThrowingBox<Data>

    public init<V>(_ value: V) where V: Codable {
        base = value
        _mangledTypeName = Swift._mangledTypeName(V.self) ?? _typeName(V.self)

        _baseDataBox = MemoizedThrowingBox {
            let encoder = JSONEncoder()
            return try encoder.encode(value)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let baseData = try container.decode(Data.self, forKey: .baseData)
        _mangledTypeName = try container.decode(String.self, forKey: .mangledTypeName)
        _baseDataBox = MemoizedThrowingBox { baseData }

        let jsonDecoder = JSONDecoder()
        guard let targetType = _typeByName(_mangledTypeName) as? Decodable.Type else {
            throw DecodingError.typeMismatch(AnyCodable.self,
                                             DecodingError.Context(codingPath: container.codingPath,
                                                                   debugDescription: "Invalid encode type found",
                                                                   underlyingError: nil))
        }

        base = try jsonDecoder.decode(targetType, from: baseData)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_baseDataBox.fetchValue(), forKey: .baseData)
        try container.encode(_mangledTypeName, forKey: .mangledTypeName)
    }
}

extension AnyCodable: Hashable {
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        let lhsData = try? lhs._baseDataBox.fetchValue()
        let rhsData = try? rhs._baseDataBox.fetchValue()

        return lhs._mangledTypeName == rhs._mangledTypeName && lhsData == rhsData
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_mangledTypeName)
        hasher.combine(try? _baseDataBox.fetchValue())
    }
}

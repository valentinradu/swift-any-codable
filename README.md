# AnyCodable

Type erasure for `Codable` that works with any type. Please read the security implications below.

## Installation

Via SPM:

```swift
dependencies: [
    // ..
    .package(url: "https://github.com/valentinradu/swift-any-codable.git", from: .init(0, 0, 1))
],
// ..
targets: [
    .target(
        // ..
        dependencies: [
            .product(name: "AnyCodable", package: "swift-any-codable")
        ]
    )
]
```

## Usage
 
```
    let wrappedCodable = AnyCodable("Hello World")
    // The original object can be accessed through `base`
    assert(wrappedCodable.base as? String == "Hello World")
```

## FAQs

### This is using private APIs, will it cause problems during app reiview? 

No. While `_mangledTypeName`, `_typeByName` and `_typeName` are private, they are not part of Apple frameworks, but rather part of Swift. 
Additionally, Apple's own [distributed actors](https://github.com/apple/swift-distributed-actors.git) implementation uses the same approach
    
### Is this safe?

Generally speaking, yes, especially if you use it with entities that don't have behavior, only state. 
However, it's important to understand the potential implications. 
The problem arises when someone can inject arbitrary data that gets decoded as an `AnyCodable`. 
In this case, `AnyCodable` will try to find the encoded type using `_typeByName` from a string. If an attacker carefully crafts the string to contain another type that you don't expect, you could end up calling `doSomething()` on that type (as long as it conforms to `SomeProtocol` as well). 
While exploiting this vulnerability is difficult, it is theoretically possible.

```swift 
    let decoder = JSONDecoder()
    let decodedValue = try decoder.decode(AnyCodable.self, from: data)
    
    if decodedValue.base as? SomeProtocol {
        // decodedValue could be of an unexpected type that conforms to `SomeProtocol`
        decodedValue.doSomething()
    }
}
``` 

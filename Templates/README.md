# Templates

## Swift

Original (not changed)

## Swift-SAPURLSession

### Motivation

Being able to generate client APIs in Swift based on OpenAPI/Swagger 3.0 with a different networking library, i.e use **`SAPFoundation`** **without** `Alamofire` for networking handling.

Generated code intended to be further wrapped by application / framework developer as needed and integrated without Swift Package Manager.

### Template

New template `Templates/Swift-SAPURLSession` was created as a copy of `Templates/Swift` and modified in such a way that it
- removes dependencies to `Alamofire` APIs
- uses SAPFoundation and its `SAPURLSession` class
- does not create a Swift Package
- applies access level `internal` (but can be changed back with option `apiAccessLevel`)

### How-to use

*Note*: you can use the official swaggen command line tool (e.g. installed through Homebrew) as changes in this fork are all encapsulated in the new template! 

Example call (assuming to be called in root folder of this repository)

```bash
swaggen generate /Users/<UserName>/<project>/openapi.yaml --template Templates/Swift-SAPURLSession --destination /Users/<UserName>/<project>/generation --option name:MyService
```

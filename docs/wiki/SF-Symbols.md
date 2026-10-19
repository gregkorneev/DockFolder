# SF Symbols catalog

DockFolders uses Apple's system-provided SF Symbols through the public AppKit `NSImage(systemSymbolName:accessibilityDescription:)` API. Apple describes SF Symbols as a library of more than 7,000 symbols and documents this API as the way to load a named system symbol.

The picker includes 7,752 symbol identifiers from the SF Symbols 7.0 name catalog. It bundles the identifier list only; macOS supplies and draws the artwork at runtime. The identifier catalog is generated from the MIT-licensed [SFSafeSymbols project](https://github.com/SFSafeSymbols/SFSafeSymbols), commit `cb2e670a213ff42ae08528ee2c401bfb1d799675`; its license is in `THIRD_PARTY_NOTICES_SFSafeSymbols.txt`. DockFolders does not include SFSafeSymbols as a dependency.

Apple Shortcuts does not provide a public icon-pack API or a redistributable package for its picker. The app therefore uses SF Symbols, not extracted Shortcuts assets. SF Symbols names and availability can change with operating-system releases; the current bundled name list tracks SF Symbols 7.0 and the target macOS version determines which symbol images render.

Apple notes that some SF Symbols depict Apple products or features: they may be displayed in an app but must not be customized. Apple marks these symbols and describes their restrictions in the SF Symbols app. There is no public AppKit API to enumerate the catalog or retrieve each symbol's restriction metadata, so users should check the SF Symbols app before applying a custom appearance to a product symbol. See [Apple's SF Symbols HIG](https://developer.apple.com/design/human-interface-guidelines/sf-symbols) and [AppKit system-symbol initializer](https://developer.apple.com/documentation/appkit/nsimage/init%28systemsymbolname%3Aaccessibilitydescription%3A%29).

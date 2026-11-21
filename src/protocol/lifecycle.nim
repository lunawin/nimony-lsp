type LspCapabilitiesDocumentSync* = object
    openClose*: bool
    change*: int
    save*: bool

type LspCapabilities* = object
    textDocumentSync*: LspCapabilitiesDocumentSync
    definitionProvider*: bool

type LspInformation* = object
    name*: string
    version*: string

type LspInitializeResponse* = object
    capabilities*: LspCapabilities
    serverInfo*: LspInformation
type LspWindowType* = enum
    LWTError   = 1
    LWTWarning = 2
    LWTInfo    = 3
    LWTLog     = 4

type LspShowWindow* = object
    `type`*: int
    message*: string
import std/syncio

type LspContext* = ref object
    shuttingDown*: bool

proc newLspContext*(): LspContext =
    result = LspContext(
        shuttingDown: false
    )

proc lsplog*(items: varargs[string, `$`]) =
    var to_write = "Nimony-LSP: "
    for item in items:
        to_write &= item
        to_write &= " "
    stderr.writeLine(to_write)
    stderr.flushFile()
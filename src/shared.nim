import std/syncio

proc lsplog*(items: varargs[string, `$`]) =
    var to_write = "Nimony-LSP: "
    for item in items:
        to_write &= item
        to_write &= " "
    stderr.writeLine(to_write)
    stderr.flushFile()
import std/tables
import std/syncio
import std/json
import nifcore
import documents

type LspContext* = ref object
    shuttingDown*: bool
    documents*: LspDocuments

proc newLspContext*(): LspContext =
    result = LspContext(
        shuttingDown: false,
        documents: newLspDocuments()
    )

proc lsplog*(items: varargs[string, `$`]) =
    var to_write = "Nimony-LSP: "
    for item in items:
        to_write &= item
        to_write &= " "
    stderr.writeLine(to_write)
    stderr.flushFile()

# copied directly from compiler
proc nullNode(): JsonNode =
    var t = createJsonTree()
    t.buf.openTag JKNull.tagId
    t.buf.closeTag()
    result = t.root

# same logic as std/json.`{}` but for JsonNode
proc getField*(node: JsonNode, key: string): JsonNode =
    if node.kind == JObject:
        for k, v in node.pairs:
            if k == key:
                return v
    return nullNode()
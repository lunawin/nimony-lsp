import std/tables
import std/syncio
import std/json
import std/strutils
import std/uri
import nifcore
import documents

type LspContext* = ref object
    shuttingDown*: bool
    documents*: LspDocuments
    rootPath*: string
    rootUri*: string

proc newLspContext*(): LspContext =
    result = LspContext(
        shuttingDown: false,
        documents: newLspDocuments(),
        rootPath: "",
        rootUri: ""
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


proc getAbsolute*(rootPath: string, path: string): string =
    var path2 = path.replace("\\", "/")
    if (path2.len >= 3) and (path2[1] == ':') and (path2[2] == '/'):
        return path
    else:
        return rootPath & "/" & path2

proc getFilePathFromUri*(uri: string): string {.raises.} =
    var partialPath = uri[len("file:///") .. ^1]
    result = decodeUrl(partialPath, false)
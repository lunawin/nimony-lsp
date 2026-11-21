import std/json
import std/strutils
import std/osproc
import std/uri
import shared
import jsonrpc

type DefinitionPosition* = object
    line*: int
    character*: int

type DefinitionRange* = object
    start*: DefinitionPosition
    `end`*: DefinitionPosition

type DefinitionLocation* = object
    uri*: string
    `range`*: DefinitionRange

proc getDefinitionLocations(workingDirectory: string, path: string, lineNo: int, charNo: int): seq[tuple[filename: string, lineNo: int, charNo: int]] {.raises.} =
    var process = startProcess(
        "nimony",
        workingDirectory,
        @["check", "--def:" & path & "," & $lineNo & "," & $charNo, path]
    )

    result = @[]
    for line in process.lines:
        if line == "symbol not found": return
        if not line.startsWith("def"):
            break
        var parts = line.split("\t")
        result.add((
            filename: parts[^3],
            lineNo: parts[^2].parseInt,
            charNo: parts[^1].parseInt
        ))
    process.close()

proc handleDefinition*(lspCtx: LspContext, request: RpcRequest) {.raises.} =
    if request.parameters.kind != JObject:
        return
    var textDocument = request.parameters.getField("textDocument")
    if textDocument.kind != JObject:
        return
    var position = request.parameters.getField("position")
    if position.kind != JObject:
        return

    var lineNo = position.getField("line").getInt() + 1
    var charNo = position.getField("character").getInt() + 1

    var rawDocumentUri = textDocument.getField("uri").getStr()
    var filePath = getFilePathFromUri(rawDocumentUri)
    
    var rootPath = lspCtx.rootPath.replace("\\", "/") & "/"
    if filePath.startsWith(rootPath):
        filePath = filePath[len(rootPath) .. ^1]
    
    var locations = getDefinitionLocations(
        lspCtx.rootPath,
        filePath,
        lineNo,
        charNo
    )
    
    var toSend: seq[DefinitionLocation] = @[]
    for location in locations:
        var path = getAbsolute(lspCtx.rootPath.replace("\\", "/"), location.filename)
        var uri = "file:///" & encodeUrl(path, false).replace("%2F", "/")
        
        var start = DefinitionPosition(line: location.lineNo - 1, character: location.charNo)
        var `end` = DefinitionPosition(line: start.line, character: start.character + 999)
        var `range` = DefinitionRange(start: start, `end`: `end`)
        var toAdd = DefinitionLocation(
            uri: uri,
            `range`: `range`
        )
        toSend.add(toAdd)
    writeRpcResponse(request.id, toSend)
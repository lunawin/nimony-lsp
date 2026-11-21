import std/osproc
import std/strutils
import std/syncio
import std/uri
import std/tables
import shared
import jsonrpc

type LspNimonyCheckResult = object
    path: string
    logType: string
    lineNo: int
    charNo: int
    shortMessage: string
    details: string

type DiagnosticPosition = object
    line: int
    character: int

type DiagnosticRange = object
    start: DiagnosticPosition
    `end`: DiagnosticPosition

type Diagnostic = object
    `range`: DiagnosticRange
    severity: int
    source: string
    message: string

type LspDiagnostics = object
    uri*: string
    diagnostics*: seq[Diagnostic]

const dummyCheckResult = LspNimonyCheckResult(path: "!!DUMMY!!", lineNo: -1, charNo: -1, shortMessage: "!!DUMMY!!", details: "!!DUMMY!!")
const markers = ["Error:", "Trace:"]
const fillerMarkers = ["nifmake: ", "FAILURE:"]

proc isStarterLine(line: string): bool =
    if line.startsWith("["):
        return false
    for marker in markers:
        if marker in line:
            return true
    return false

proc parseStarterLine(line: string): LspNimonyCheckResult {.raises.} =
    var lparenIndex = line.find("(")
    if lparenIndex < 0:
        return dummyCheckResult
    var commaIndex = line.find(", ", lparenIndex)
    if commaIndex < 0:
        return dummyCheckResult
    var rparenIndex = line.find(")", commaIndex)
    if rparenIndex < 0:
        return dummyCheckResult
    var colonIndex = line.find(": ", rparenIndex)
    if colonIndex < 0:
        return dummyCheckResult

    var path         = line[0               ..< lparenIndex]
    var lineNo       = line[(lparenIndex+1) ..< commaIndex].parseInt
    var charNo       = line[(commaIndex+2) ..< rparenIndex].parseInt
    var logType      = line[(rparenIndex+2) ..< colonIndex]
    var shortMessage = line[(colonIndex+2) .. ^1]

    result = LspNimonyCheckResult(
        path: path,
        logType: logType,
        lineNo: lineNo,
        charNo: charNo,
        shortMessage: shortMessage,
        details: ""
    )

proc isFillerLine(line: string): bool =
    for marker in fillerMarkers:
        if line.startsWith(marker):
            return true
    return false

proc lspGetCheckDiagnostics(workingDirectory: string, path: string): seq[LspNimonyCheckResult] {.raises.} =
    var command = "nimony check \"" & path & "\""
    var process = startProcess("nimony", workingDirectory, @["check", path])

    var processingCheckResult = false
    var currentCheckResult = dummyCheckResult

    result = @[]
    for line in process.lines:
        if isStarterLine(line):
            if processingCheckResult:
                result.add(currentCheckResult)
            processingCheckResult = true
            currentCheckResult = parseStarterLine(line)
            if currentCheckResult.path == dummyCheckResult.path:
                raise ErrorCode.ValueError
        elif isFillerLine(line):
            break
        else:
            currentCheckResult.details &= line & "\n"
    if processingCheckResult:
        result.add(currentCheckResult)
    process.close()

proc getAbsolute(rootPath: string, path: string): string =
    var path2 = path.replace("\\", "/")
    if (path2.len >= 3) and (path2[1] == ':') and (path2[2] == '/'):
        return path
    else:
        return rootPath & "/" & path2

proc lspPublishDiagnostics*(lspCtx: LspContext, recentlyModifiedFileUri: string) {.raises.} =
    if not recentlyModifiedFileUri.startsWith("file:///"):
        return
    var partialPath = recentlyModifiedFileUri[(len("file:///")) .. ^1]
    var filePath = decodeUrl(partialPath, false)
    var checkResults = lspGetCheckDiagnostics(lspCtx.rootPath, filePath)

    var uriToDiagnostics = initTable[string, seq[Diagnostic]]()
    for document in uncheckedBorrow(lspCtx.documents.documents).keys:
        var doc = lspCtx.documents.documents[document]
        uriToDiagnostics[doc.uri] = @[]

    for checkResult in checkResults:
        var path = getAbsolute(lspCtx.rootPath.replace("\\", "/"), checkResult.path)
        var uri = "file:///" & encodeUrl(path, false).replace("%2F", "/")
        if uri notin uriToDiagnostics:
            uriToDiagnostics[uri] = @[]

        var positionStart = DiagnosticPosition(line: checkResult.lineNo-1, character: checkResult.charNo-1)
        var positionEnd = DiagnosticPosition(line: positionStart.line, character: positionStart.character + 5)
        var severity = 0

        if checkResult.logType == "Error":
            severity = 1
        else:
            severity = 3
        
        var diagnostic = Diagnostic(
            `range`: DiagnosticRange(start: positionStart, `end`: positionEnd),
            severity: severity,
            source: "Nimony-LSP",
            message: checkResult.shortMessage & "\n" & checkResult.details
        )
        uriToDiagnostics[uri].add(diagnostic)
    
    for k, v in uriToDiagnostics.pairs:
        writeRpcNotification(
            "textDocument/publishDiagnostics",
            LspDiagnostics(
                uri: k,
                diagnostics: v
            )
        )
import std/osproc
import std/strutils
import std/syncio

type LspNimonyCheckResult = object
    path: string
    logType: string
    lineNo: int
    charNo: int
    shortMessage: string
    details: string

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
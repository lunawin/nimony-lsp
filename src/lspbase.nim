import std/syncio
import std/strutils
import shared

proc readRawMessage*(): string {.raises.} =
    var contentLength = -1
    var isFirstLine = true
    while true:
        let currentLine = stdin.readLine().strip().toLowerAscii()
        if currentLine.len == 0:
            if isFirstLine:
                raise ErrorCode.EndOfStreamError
            break
        if currentLine.startsWith("content-length:"):
            let numberString = currentLine[len("content-length:") .. ^1].strip()
            contentLength = numberString.parseInt()
        isFirstLine = false

    if contentLength <= 0:
        raise ErrorCode.ProtocolError
    
    result = newString(contentLength)
    let writableString = result.toCString()

    var totalReadBytes = 0
    while totalReadBytes < contentLength:
        let newlyReadBytes = stdin.readBuffer(
            addr writableString[totalReadBytes], 
            contentLength - totalReadBytes
        )
        if newlyReadBytes <= 0:
            raise ErrorCode.EndOfStreamError
        totalReadBytes += newlyReadBytes

proc writeRawMessage*(message: string) {.raises.} =
    var toWrite = ""
    toWrite &= "Content-Length: " & $(message.len) & "\r\n"
    toWrite &= "\r\n"
    toWrite &= message

    stdout.write(toWrite)
    stdout.flushFile()
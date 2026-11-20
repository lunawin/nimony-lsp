import std/syncio
import std/strutils
import std/os

proc lsplog(items: varargs[string, `$`]) =
    stderr.write("NLSP: ")
    for item in items:
        stderr.write(item)
    stderr.writeLine("")

proc lspbase_internal_readLine(): string =
    result = ""
    try:
        result = stdin.readLine()
    except ErrorCode as e:
        lsplog("Reading failed due to ", e)
        quit 1

proc lspbase_internal_get_content_length(): int =
    let first_line = lspbase_internal_readLine()
    let length_str = first_line[ len("Content-Length: ") .. ^1 ]
    result = 0
    try:
        result = parseInt(length_str)
    except ErrorCode as e:
        lsplog("Reading content length failed due to ", e)
        quit 1
    if lspbase_internal_readLine().len != 0:
        lsplog("Expected empty line.")
        quit 1

proc lspbase_read(): string =
    result = ""
    let content_length = lspbase_internal_get_content_length()
    result = newString(content_length)
    let base_ptr = cast[ptr UncheckedArray[char]](result.toCString)
    
    var remaining = content_length
    while remaining > 0:
        let new_read = stdin.readBuffer(addr(base_ptr[content_length - remaining]), remaining)
        if new_read <= 0:
            lsplog("Unexpected EOF while reading.")
            quit 1
        remaining -= new_read


    

while true:
    let request = lspbase_read()
    lsplog request
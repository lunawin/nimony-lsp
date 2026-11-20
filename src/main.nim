import std/syncio
import lspbase
import shared

lsplog("=============================")
lsplog("LSP is currently running now.")

while true:
    try:
        lsplog(readRawMessage())
    except ErrorCode as e:
        stderr.write($e)
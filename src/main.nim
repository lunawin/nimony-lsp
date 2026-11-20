import std/syncio
import lspbase
import shared

lsplog("LSP is currently running now.")

while true:
    try:
        lsplog lspbase_read_raw()
    except ErrorCode as e:
        stderr.write($e)
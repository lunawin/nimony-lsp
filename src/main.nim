import shared
import lspbase
import jsonrpc
import handlers

var lspCtx = LspContext()

lsplog("=============================")
lsplog("LSP is currently running now.")

while true:
    try:
        let rpcRequest = readRpcMessage()

        case rpcRequest.methodName
            of "initialize":
                handleInitialize(lspCtx, rpcRequest)
            of "initialized":
                lsplog("Successfully initialized.")
            
            # TODO: Handle below properly
            of "shutdown":
                lsplog("Was asked to shutdown.")
                var toWrite = ""
                toWrite &= """{"jsonrpc": "2.0", """
                toWrite &= """ "id": """ & $rpcRequest.id & ", "
                toWrite &= """ "result": null """
                toWrite &= "}"
                writeRawMessage(toWrite)
            of "exit":
                lsplog("Was asked to exit.")
                break
            
            else:
                lsplog("Unsupported", rpcRequest.methodName)
    
    except ErrorCode as e:
        lsplog("Error:", e)
        break
import shared
import lspbase
import jsonrpc
import handlers

import protocol/window # TODO: Cleanup, this is just testing

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
                writeRpcNotification(
                    "window/logMessage", 
                    LspShowWindow(
                        `type`: ord(LWTInfo),
                        message: "Nimony-LSP initialized..."
                    )
                )
            
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
                if rpcRequest.id >= 0:
                    writeRpcError(rpcRequest.id, RECMethodNotFound, "Method not found")
    
    except ErrorCode as e:
        lsplog("Error:", e)
        break
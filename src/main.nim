import shared
import lspbase
import jsonrpc
import handlers

var lspCtx = newLspContext()

lsplog("=============================")
lsplog("LSP is currently running now.")

while true:
    try:
        let rpcRequest = readRpcMessage()

        if lspCtx.shuttingDown:
            if rpcRequest.methodName == "exit":
                lsplog("Was asked to exit.")
                break
            else:
                if rpcRequest.id >= 0:
                    writeRpcError(rpcRequest.id, RECInvalidRequest, "Invalid request.")
                continue

        case rpcRequest.methodName
            of "initialize":
                handleInitialize(lspCtx, rpcRequest)
            of "initialized":
                lsplog("Successfully initialized.")

            # TODO: Handle below properly
            of "shutdown":
                lspCtx.shuttingDown = true
                lsplog("Was asked to shutdown.")
                var toWrite = ""
                toWrite &= """{"jsonrpc": "2.0", """
                toWrite &= """ "id": """ & $rpcRequest.id & ", "
                toWrite &= """ "result": null """
                toWrite &= "}"
                writeRawMessage(toWrite)
            of "exit":
                lsplog("Was asked to exit without shutdown.")
                break
            
            of "textDocument/didOpen":
                handleDidOpen(lspCtx, rpcRequest)
            
            of "textDocument/didClose":
                handleDidClose(lspCtx, rpcRequest)
            
            of "textDocument/didChange":
                handleDidChange(lspCtx, rpcRequest)
            
            of "textDocument/didSave":
                handleDidSave(lspCtx, rpcRequest)

            else:
                lsplog("Unsupported", rpcRequest.methodName)
                if rpcRequest.id >= 0:
                    writeRpcError(rpcRequest.id, RECMethodNotFound, "Method not found")
    
    except ErrorCode as e:
        lsplog("Error:", e)
        break
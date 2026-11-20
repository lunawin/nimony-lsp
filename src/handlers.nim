import std/json
import shared
import jsonrpc
import protocol/lifecycle

proc handleInitialize*(lspCtx: LspContext, request: RpcRequest) {.raises.} =
    lsplog("Was asked to initialize")
    var response = LspInitializeResponse(
        capabilities: LspCapabilities(
            textDocumentSync: LspCapabilitiesDocumentSync(
                openClose: false,
                change: 0,
                save: false
            )
        ),
        serverInfo: LspInformation(
            name: "Nimony-LSP",
            version: "0.1.0"
        )
    )
    writeRpcResponse(request.id, response)
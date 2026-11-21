import std/json
import shared
import jsonrpc
import protocol/lifecycle
import documents

proc handleInitialize*(lspCtx: LspContext, request: RpcRequest) {.raises.} =
    lsplog("Was asked to initialize")
    var response = LspInitializeResponse(
        capabilities: LspCapabilities(
            textDocumentSync: LspCapabilitiesDocumentSync(
                openClose: true,
                change: 1,
                save: true
            )
        ),
        serverInfo: LspInformation(
            name: "Nimony-LSP",
            version: "0.1.0"
        )
    )
    writeRpcResponse(request.id, response)

proc handleDidOpen*(lspCtx: LspContext, request: RpcRequest) {.raises.} =
    if request.parameters.kind != JObject:
        return
    var textDocument = request.parameters.getField("textDocument")
    if textDocument.kind != JObject:
        return
    
    var documentUri = textDocument.getField("uri").getStr()
    var documentType = textDocument.getField("languageId").getStr()
    var documentVersion = textDocument.getField("version").getInt()
    var documentText = textDocument.getField("text").getStr()

    lspCtx.documents.addDocument(documentUri, documentVersion, documentType, documentText)
    # TODO: nimony check
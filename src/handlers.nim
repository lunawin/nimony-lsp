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

proc handleDidClose*(lspCtx: LspContext, request: RpcRequest) {.raises.} =
    if request.parameters.kind != JObject:
        return
    var textDocument = request.parameters.getField("textDocument")
    if textDocument.kind != JObject:
        return
    var documentUri = textDocument.getField("uri").getStr()
    lspCtx.documents.removeDocument(documentUri)

proc handleDidChange*(lspCtx: LspContext, request: RpcRequest) {.raises.} =
    if request.parameters.kind != JObject:
        return
    var textDocument = request.parameters.getField("textDocument")
    var documentUri = textDocument.getField("uri").getStr()
    var documentVersionNew = textDocument.getField("version").getInt()

    if documentUri notin lspCtx.documents.documents:
        return

    var contentChanges = request.parameters.getField("contentChanges")
    for v in contentChanges.items:
        for k, v2 in v.pairs:
            if k == "text":
                lspCtx.documents.updateDocument(documentUri, documentVersionNew, v2.getStr())
    
    # TODO: nimony check
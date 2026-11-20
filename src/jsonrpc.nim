import std/json
import shared
import lspbase

type RpcRequest* = object
    id*: int # Notifications are -1
    methodName*: string
    tree: JsonTree
    parameters*: JsonNode

proc readRpcMessage*(): RpcRequest {.raises.} =
    let rawMessage = readRawMessage()
    var jsonTree = parseJson(rawMessage)

    if jsonTree.root.kind != JObject:
        raise ErrorCode.ProtocolError
    
    var versionNode = jsonTree{"jsonrpc"}
    if versionNode.kind != JString:
        raise ErrorCode.ProtocolError
    if versionNode.getStr() != "2.0":
        raise ErrorCode.ProtocolError
    
    var id = -1
    var idNode = jsonTree{"id"}
    if idNode.kind != JNull:
        if idNode.kind != JInt:
            raise ErrorCode.ProtocolError
        id = idNode.getInt()
    
    var methodNode = jsonTree{"method"}
    if methodNode.kind != JString:
        raise ErrorCode.ProtocolError
    var methodName = methodNode.getStr()

    var parametersNode = jsonTree{"params"}
    if (parametersNode.kind != JObject) and (parametersNode.kind != JNull):
        raise ErrorCode.ProtocolError

    result = RpcRequest(
        id: id,
        methodName: methodName,
        tree: jsonTree,
        parameters: parametersNode
    )
    
proc writeRpcResponse*[T](requestId: int, response: T) {.raises.} =
    var jsonifiedResponse = toJson(response)
    var toWrite = ""
    toWrite &= """{"jsonrpc": "2.0", """
    toWrite &= """ "id": """ & $requestId & ", "
    toWrite &= """ "result": """ & $jsonifiedResponse
    toWrite &= "}"
    writeRawMessage(toWrite)
import std/json
import shared
import lspbase

type RpcRequest* = object
    id*: int # Notifications are -1
    methodName*: string
    tree: JsonTree
    parameters*: JsonNode

type RpcResponseError* = object
    code*: int
    message*: string

type RpcErrorCode* = enum
    RECParseError     = -32700
    RECInternalError  = -32603
    RECInvalidParams  = -32602
    RECMethodNotFound = -32601
    RECInvalidRequest = -32600

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

proc writeRpcError*(requestId: int, code: RpcErrorCode, message: string) {.raises.} =
    var response = RpcResponseError(code: ord(code), message: message)
    var jsonifiedResponse = toJson(response)
    var toWrite = ""
    toWrite &= """{"jsonrpc": "2.0", """
    toWrite &= """ "id": """ & $requestId & ", "
    toWrite &= """ "error": """ & $jsonifiedResponse
    toWrite &= "}"
    writeRawMessage(toWrite)

proc writeRpcNotification*[T](methodName: string, notification: T) {.raises.} =
    var jsonifiedResponse = toJson(notification)
    var jsonifiedMethodName = toJson(methodName)
    var toWrite = ""
    toWrite &= """{"jsonrpc": "2.0", """
    toWrite &= """ "method": """ & $jsonifiedMethodName & ", "
    toWrite &= """ "params": """ & $jsonifiedResponse
    toWrite &= "}"
    writeRawMessage(toWrite)
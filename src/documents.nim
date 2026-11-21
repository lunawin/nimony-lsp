import std/tables

type LspDocument* = object
    uri*: string
    version*: int
    languageId*: string
    text*: string

type LspDocuments* = ref object
    documents*: Table[string, LspDocument]

proc newLspDocuments*(): LspDocuments = 
    result = LspDocuments(
        documents: initTable[string, LspDocument]()
    )

proc addDocument*(lspdocs: LspDocuments, uri: string, version: int, languageId: string, text: string) =
    lspdocs.documents[uri] = LspDocument(
        uri: uri,
        version: version,
        languageId: languageId,
        text: text
    )

proc removeDocument*(lspdocs: LspDocuments, uri: string) =
    lspdocs.documents.del uri

proc updateDocument*(lspdocs: LspDocuments, uri: string, newVersion: int, newText: string) {.raises.} =
    lspdocs.documents[uri].version = newVersion
    lspdocs.documents[uri].text = newText
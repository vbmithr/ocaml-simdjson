type jsonparser
type element

external createParser : unit -> jsonparser = "createParser_stubs"
external loadBuf : jsonparser -> Bigstringaf.t -> element = "loadBuf_stubs"

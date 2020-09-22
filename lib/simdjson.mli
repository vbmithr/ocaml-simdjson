type jsonparser
type element

val createParser : unit -> jsonparser
val loadBuf : jsonparser -> Bigstringaf.t -> element

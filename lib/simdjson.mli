type jsonparser
type value
type obj
type objIter
type array
type arrayIter

val createParser : unit -> jsonparser
val loadBuf : jsonparser -> Bigstringaf.t -> value
val view : value -> value Json_repr.view
val repr : value Json_repr.view -> value
val repr_uid : value Json_repr.repr_uid

(**/*)

val getObject : value -> obj
val getArray : value -> array

(* *)
val arraySize : array -> int
val arrayIterator : array -> arrayIter
val arrayIteratorGet : arrayIter -> value
val arrayIteratorNext : arrayIter -> unit

(* *)
val objSize : obj -> int
val objIterator : obj -> objIter
val objIteratorGet : objIter -> string * value
val objIteratorNext : objIter -> unit

(* *)
val elementType : value -> char

(* *)
val getInt : value -> int
val getInt64 : value -> int64
val getDouble : value -> float
val getString : value -> string
val getBool : value -> bool

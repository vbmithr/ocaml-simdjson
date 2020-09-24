type jsonparser
type value
type docStream
type docStreamIter
type obj
type objIter
type array
type arrayIter

val createParser : unit -> jsonparser
val loadBuf : jsonparser -> Bigstringaf.t -> value
val parseMany : jsonparser -> Bigstringaf.t -> docStream
val loadMany : jsonparser -> string -> docStream
val view : value -> value Json_repr.view
val repr : value Json_repr.view -> value
val repr_uid : value Json_repr.repr_uid

(**/*)

val docStreamIteratorBegin : docStream -> docStreamIter
val docStreamIteratorEnd : docStream -> docStreamIter
val docStreamIteratorCompare : docStreamIter -> docStreamIter -> bool
val docStreamIteratorGet : docStreamIter -> value
val docStreamIteratorNext : docStreamIter -> unit
val seq_of_docStream : docStream -> value Seq.t

(* *)

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

type parser
type elt
type docStream

val createParser : unit -> parser
val parse : parser -> Bigstringaf.t -> elt
val parseMany : ?batchSize:int -> parser -> Bigstringaf.t -> docStream
val loadMany : ?batchSize:int -> parser -> string -> docStream
val seqOfDocStream : docStream -> elt Seq.t

(** Functor compatibility with ocplib-json-typed *)

type value = elt

val view : value -> value Json_repr.view
val repr : value Json_repr.view -> value
val repr_uid : value Json_repr.repr_uid

type parser
type elt
type docStream

val padding : Bigstringaf.t
(** Buffer passed to [parse] or [parseMany] must be padded by
   [padding] bytes (It does not matter what those bytes are
   initialized to). *)

val createParser : unit -> parser
val parse : ?len:int -> parser -> Bigstringaf.t -> elt

val parseMany :
  ?len:int -> ?batchSize:int -> parser -> Bigstringaf.t -> docStream

val load : parser -> string -> elt
val loadMany : ?batchSize:int -> parser -> string -> docStream
val seqOfDocStream : docStream -> elt Seq.t

(** Functor compatibility with ocplib-json-typed *)

type value = elt

val view : value -> value Json_repr.view
val repr : value Json_repr.view -> value
val repr_uid : value Json_repr.repr_uid

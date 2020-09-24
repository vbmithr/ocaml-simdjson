type jsonparser
type value
type obj
type objIter
type array
type arrayIter
type docStream
type docStreamIter

external elementType : value -> char = "elementType_stubs" [@@noalloc]
external createParser : unit -> jsonparser = "createParser_stubs"
external loadBuf : jsonparser -> Bigstringaf.t -> value = "loadBuf_stubs"
external getObject : value -> obj = "getObject_stubs"
external getArray : value -> array = "getArray_stubs"
external loadMany : jsonparser -> string -> docStream = "loadMany_stubs"

external parseMany : jsonparser -> Bigstringaf.t -> docStream
  = "parseMany_stubs"

(* *)
external docStreamIteratorBegin : docStream -> docStreamIter
  = "docStreamIteratorBegin_stubs"

external docStreamIteratorEnd : docStream -> docStreamIter
  = "docStreamIteratorEnd_stubs"

external docStreamIteratorCompare : docStreamIter -> docStreamIter -> bool
  = "docStreamIteratorCompare_stubs"
  [@@noalloc]

external docStreamIteratorGet : docStreamIter -> value
  = "docStreamIteratorGet_stubs"

external docStreamIteratorNext : docStreamIter -> unit
  = "docStreamIteratorNext_stubs"
  [@@noalloc]

let seq_of_docStream d =
  let iter_end = docStreamIteratorEnd d in
  let iter = docStreamIteratorBegin d in
  let rec loop () =
    match docStreamIteratorCompare iter iter_end with
    | false -> Seq.Nil
    | true ->
        let x = docStreamIteratorGet iter in
        (* Printf.printf "%c%!" (elementType x) ; *)
        docStreamIteratorNext iter ;
        Seq.Cons (x, loop) in
  loop

(* *)
external arraySize : array -> int = "arraySize_stubs" [@@noalloc]
external arrayIterator : array -> arrayIter = "arrayIterator_stubs"
external arrayIteratorGet : arrayIter -> value = "arrayIteratorGet_stubs"

external arrayIteratorNext : arrayIter -> unit = "arrayIteratorNext_stubs"
  [@@noalloc]

(* *)
external objSize : obj -> int = "objSize_stubs" [@@noalloc]
external objIterator : obj -> objIter = "objIterator_stubs"
external objIteratorGet : objIter -> string * value = "objIteratorGet_stubs"
external objIteratorNext : objIter -> unit = "objIteratorNext_stubs" [@@noalloc]

(* *)
external getInt : value -> int = "getInt_stubs" [@@noalloc]
external getBool : value -> bool = "getBool_stubs" [@@noalloc]
external getInt64 : value -> int64 = "getInt64_stubs"
external getDouble : value -> float = "getDouble_stubs"
external getString : value -> string = "getString_stubs"

let view elt =
  match elementType elt with
  | '[' ->
      let a = getArray elt in
      let len = arraySize a in
      let iter = arrayIterator a in
      let rec loop acc len =
        if len < 0 then List.rev acc
        else
          let e = arrayIteratorGet iter in
          arrayIteratorNext iter ;
          loop (e :: acc) (pred len) in
      `A (loop [] (pred len))
  | '{' ->
      let o = getObject elt in
      let len = objSize o in
      let iter = objIterator o in
      let rec loop acc len =
        if len < 0 then List.rev acc
        else
          let k, v = objIteratorGet iter in
          objIteratorNext iter ;
          loop ((k, v) :: acc) (pred len) in
      `O (loop [] (pred len))
  | 'l' -> `Float (Int64.to_float (getInt64 elt))
  | 'u' ->
      let x = getInt64 elt in
      let x =
        if x < 0L then Int64.(to_float (neg min_int) +. to_float (neg x))
        else Int64.to_float x in
      `Float x
  | 'd' -> `Float (getDouble elt)
  | '"' -> `String (getString elt)
  | 't' -> `Bool (getBool elt)
  | 'n' -> `Null
  | _ -> assert false

let repr _ = assert false
let repr_uid = Json_repr.repr_uid ()

type jsonparser
type value
type obj
type objIter
type array
type arrayIter

external createParser : unit -> jsonparser = "createParser_stubs"
external loadBuf : jsonparser -> Bigstringaf.t -> value = "loadBuf_stubs"
external createObject : unit -> obj = "createObject_stubs"
external createArray : unit -> array = "createObject_stubs"
external getObject : obj -> value -> unit = "getObject_stubs"
external getArray : array -> value -> unit = "getArray_stubs"

(* *)
external arraySize : array -> int = "arraySize_stubs" [@@noalloc]
external createArrayIterator : unit -> arrayIter = "createArrayIterator_stubs"

external arrayIterator : arrayIter -> array -> unit = "arrayIterator_stubs"
  [@@noalloc]

external arrayIteratorGet : arrayIter -> value = "arrayIteratorGet_stubs"

external arrayIteratorNext : arrayIter -> unit = "arrayIteratorNext_stubs"
  [@@noalloc]

(* *)
external objSize : obj -> int = "objSize_stubs" [@@noalloc]
external createObjectIterator : unit -> objIter = "createObjectIterator_stubs"
external objIterator : objIter -> obj -> unit = "objIterator_stubs" [@@noalloc]
external objIteratorGet : objIter -> string * value = "objIteratorGet_stubs"
external objIteratorNext : objIter -> unit = "objIteratorNext_stubs" [@@noalloc]

(* *)
external elementType : value -> char = "elementType_stubs" [@@noalloc]
external getInt : value -> int = "getInt_stubs" [@@noalloc]
external getBool : value -> bool = "getBool_stubs" [@@noalloc]
external getInt64 : value -> int64 = "getInt64_stubs"
external getDouble : value -> float = "getDouble_stubs"
external getString : value -> string = "getString_stubs"

let view elt =
  let aiter = createArrayIterator () in
  let oiter = createObjectIterator () in
  let arr = createArray () in
  let obj = createObject () in
  match elementType elt with
  | '[' ->
      getArray arr elt ;
      let len = arraySize arr in
      arrayIterator aiter arr ;
      let rec loop acc len =
        if len < 0 then List.rev acc
        else
          let e = arrayIteratorGet aiter in
          arrayIteratorNext aiter ;
          loop (e :: acc) (pred len) in
      `A (loop [] (pred len))
  | '{' ->
      getObject obj elt ;
      let len = objSize obj in
      objIterator oiter obj ;
      let rec loop acc len =
        if len < 0 then List.rev acc
        else
          let k, v = objIteratorGet oiter in
          objIteratorNext oiter ;
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

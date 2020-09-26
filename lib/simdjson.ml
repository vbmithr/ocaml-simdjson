type p
type e
type o
type oi
type a
type ai
type ds
type dsi
type parser = {p: p; mutable buf: Bigstringaf.t option}
type elt = {p: parser; e: e}
type obj = {p: parser; o: o}
type objIter = {o: obj; oi: oi}
type arr = {p: parser; a: a}
type arrIter = {a: arr; ai: ai}
type docStream = {p: parser; ds: ds}
type docStreamIter = {ds: docStream; dsi: dsi}
type value = elt

external elementType : e -> char = "elementType_stubs" [@@noalloc]
external createParser : unit -> p = "createParser_stubs"
external parse : p -> Bigstringaf.t -> e = "parse_stubs"
external loadMany : p -> string -> int -> ds = "loadMany_stubs"
external parseMany : p -> Bigstringaf.t -> int -> ds = "parseMany_stubs"

(* *)
(* external getInt : e -> int = "getInt_stubs" [@@noalloc] *)
external getBool : e -> bool = "getBool_stubs" [@@noalloc]
external getInt64 : e -> int64 = "getInt64_stubs"
external getDouble : e -> float = "getDouble_stubs"
external getString : e -> string = "getString_stubs"
external getObject : e -> o = "getObject_stubs"
external getArray : e -> a = "getArray_stubs"

(* *)
external docStreamIteratorBegin : ds -> dsi = "docStreamIteratorBegin_stubs"
external docStreamIteratorEnd : ds -> dsi = "docStreamIteratorEnd_stubs"

external docStreamIteratorCompare : dsi -> dsi -> bool
  = "docStreamIteratorCompare_stubs"
  [@@noalloc]

external docStreamIteratorGet : dsi -> e = "docStreamIteratorGet_stubs"

external docStreamIteratorNext : dsi -> unit = "docStreamIteratorNext_stubs"
  [@@noalloc]

(* *)
external arraySize : a -> int = "arraySize_stubs" [@@noalloc]
external arrayIterator : a -> ai = "arrayIterator_stubs"
external arrayIteratorGet : ai -> e = "arrayIteratorGet_stubs"
external arrayIteratorNext : ai -> unit = "arrayIteratorNext_stubs" [@@noalloc]

(* *)
external objSize : o -> int = "objSize_stubs" [@@noalloc]
external objIterator : o -> oi = "objIterator_stubs"
external objIteratorGet : oi -> string * e = "objIteratorGet_stubs"
external objIteratorNext : oi -> unit = "objIteratorNext_stubs" [@@noalloc]

let createParser () =
  let p = createParser () in
  {p; buf= None}

let parse p buf = {p; e= parse p.p buf}
let defaultBatchSize = 1000000

let parseMany ?(batchSize = defaultBatchSize) p buf =
  p.buf <- Some buf ;
  {p; ds= parseMany p.p buf batchSize}

let loadMany ?(batchSize = defaultBatchSize) p fn =
  {p; ds= loadMany p.p fn batchSize}

let dsb (ds : docStream) =
  let dsi = docStreamIteratorBegin ds.ds in
  {ds; dsi}

let dse (ds : docStream) =
  let dsi = docStreamIteratorEnd ds.ds in
  {ds; dsi}

let dsiCmp {dsi; _} {dsi= dsi2; _} = docStreamIteratorCompare dsi dsi2
let dsiGet {dsi; ds= {p; _}} = {p; e= docStreamIteratorGet dsi}
let dsiNext {dsi; _} = docStreamIteratorNext dsi

let seqOfDocStream ds =
  let iter_end = dse ds in
  let iter = dsb ds in
  let rec loop () =
    match dsiCmp iter iter_end with
    | false -> Seq.Nil
    | true ->
        let x = dsiGet iter in
        dsiNext iter ;
        Seq.Cons (x, loop) in
  loop

let arrGet {p; e} = {p; a= getArray e}
let getObj {p; e} = {p; o= getObject e}
let arrIter a = {a; ai= arrayIterator a.a}
let objIter o = {o; oi= objIterator o.o}
let arrIterGet {a= {p; _}; ai} = {p; e= arrayIteratorGet ai}

let objIterGet {o= {p; _}; oi} =
  let k, e = objIteratorGet oi in
  (k, {p; e})

let view elt =
  match elementType elt.e with
  | '[' ->
      let a = arrGet elt in
      let len = arraySize a.a in
      let iter = arrIter a in
      let rec loop acc len =
        if len < 0 then List.rev acc
        else
          let e = arrIterGet iter in
          arrayIteratorNext iter.ai ;
          loop (e :: acc) (pred len) in
      `A (loop [] (pred len))
  | '{' ->
      let o = getObj elt in
      let len = objSize o.o in
      let iter = objIter o in
      let rec loop acc len =
        if len < 0 then List.rev acc
        else
          let k, e = objIterGet iter in
          objIteratorNext iter.oi ;
          loop ((k, e) :: acc) (pred len) in
      `O (loop [] (pred len))
  | 'l' -> `Float (Int64.to_float (getInt64 elt.e))
  | 'u' ->
      let x = getInt64 elt.e in
      let x =
        if x < 0L then Int64.(to_float (neg min_int) +. to_float (neg x))
        else Int64.to_float x in
      `Float x
  | 'd' -> `Float (getDouble elt.e)
  | '"' -> `String (getString elt.e)
  | 't' -> `Bool (getBool elt.e)
  | 'n' -> `Null
  | _ -> assert false

let repr _ = assert false
let repr_uid = Json_repr.repr_uid ()

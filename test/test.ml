open Alcotest
module Simdjson_encoding = Json_encoding.Make (Simdjson)

let p = Simdjson.createParser ()
let buf = Bigstringaf.create 4096

let destruct_safe encoding value =
  try Simdjson_encoding.destruct encoding value
  with exn ->
    Format.eprintf "%a@." (Json_encoding.print_error ?print_unknown:None) exn ;
    raise exn

let subs json =
  let len = String.length json in
  Bigstringaf.blit_from_string json ~src_off:0 buf ~dst_off:0 ~len ;
  Bigstringaf.sub buf ~off:0 ~len:(32 + len)

let obj0 () =
  let open Simdjson in
  let json = {|[]|} in
  let subs = subs json in
  let elt = loadBuf p subs in
  let _ = view elt in
  ()

let obj () =
  let encoding = Json_encoding.(obj2 (req "object" bool) (req "machin" float)) in
  let json = {|{"object": true, "machin": 3.23}|} in
  let subs = subs json in
  let elt = Simdjson.loadBuf p subs in
  let b, fl = destruct_safe encoding elt in
  check bool "b" true b ;
  check (float 0.1) "f" 3.23 fl

let array () =
  let json = {|[0,1,2]|} in
  let subs = subs json in
  let elt = Simdjson.loadBuf p subs in
  let a = Simdjson.getArray elt in
  let len = Simdjson.arraySize a in
  check int "arraySize" 3 len ;
  let iter = Simdjson.arrayIterator a in
  for i = 0 to len - 1 do
    let e = Simdjson.arrayIteratorGet iter in
    Simdjson.arrayIteratorNext iter ;
    check int "iteratorGet" i (Simdjson.getInt e)
  done ;
  ()

let strArray () =
  let json = {|["0","1","2"]|} in
  let subs = subs json in
  let elt = Simdjson.loadBuf p subs in
  let a = Simdjson.getArray elt in
  let len = Simdjson.arraySize a in
  check int "arraySize" 3 len ;
  let iter = Simdjson.arrayIterator a in
  for i = 0 to 2 do
    let e = Simdjson.arrayIteratorGet iter in
    Simdjson.arrayIteratorNext iter ;
    check string "iteratorGet" (string_of_int i) (Simdjson.getString e)
  done ;
  ()

let parseMany () =
  let open Simdjson in
  let json = {|["0","1","2"]["0","1","2"]|} in
  let subs = subs json in
  let ds = Simdjson.parseMany p subs in
  let iter = docStreamIteratorBegin ds in
  let on_elt elt =
    let a = Simdjson.getArray elt in
    let len = Simdjson.arraySize a in
    check int "arraySize" 3 len ;
    let iter = Simdjson.arrayIterator a in
    for i = 0 to 2 do
      let e = Simdjson.arrayIteratorGet iter in
      Simdjson.arrayIteratorNext iter ;
      check string "iteratorGet" (string_of_int i) (Simdjson.getString e)
    done in
  for _ = 0 to 1 do
    let x = docStreamIteratorGet iter in
    on_elt x ; docStreamIteratorNext iter
  done

let basic =
  [ ("obj0", `Quick, obj0); ("obj", `Quick, obj); ("array", `Quick, array);
    ("strArray", `Quick, strArray); ("parseMany", `Quick, parseMany) ]

let () = run "simdjson" [("basic", basic)]

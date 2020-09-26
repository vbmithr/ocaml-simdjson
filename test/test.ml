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
  let elt = parse p subs in
  let _ = view elt in
  Gc.compact () ; ()

let obj () =
  let encoding = Json_encoding.(obj2 (req "object" bool) (req "machin" float)) in
  let json = {|{"object": true, "machin": 3.23}|} in
  let subs = subs json in
  let elt = Simdjson.parse p subs in
  let b, fl = destruct_safe encoding elt in
  Gc.compact () ;
  check bool "b" true b ;
  check (float 0.1) "f" 3.23 fl

let parseMany () =
  let open Simdjson in
  let json = {|["0","1","2"]["0","1","2"]|} in
  let subs = subs json in
  let ds = Simdjson.parseMany p subs in
  let enc = Json_encoding.(array string) in
  let on_elt acc x =
    Gc.compact () ;
    Simdjson_encoding.destruct enc x :: acc in
  let _ = Seq.fold_left on_elt [] (seqOfDocStream ds) in
  ()

let basic =
  [ ("obj0", `Quick, obj0); ("obj", `Quick, obj);
    ("parseMany", `Quick, parseMany) ]

let () = run "simdjson" [("basic", basic)]

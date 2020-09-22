open Alcotest

let init () =
  let _parser = Simdjson.createParser () in
  ()

let basic = [("init", `Quick, init)]
let () = run "simdjson" [("basic", basic)]

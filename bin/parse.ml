open Core
open Async

module Simdjson = struct
  module Simdjson_encoding = Json_encoding.Make (Simdjson)

  let padding =
    let buf = Bigstring.create 32 in
    Bigstring.memset buf ~pos:0 ~len:32 '\x00' ;
    buf

  let of_buf parser buffer w buf pos len =
    let rec loop pos len =
      if len <= 0 then Deferred.unit
      else
        match Bigstring.unsafe_find buf '\n' ~pos ~len with
        | idx when idx < 0 ->
            Bigbuffer.add_bigstring buffer (Bigstring.sub_shared ~pos ~len buf) ;
            Pipe.pushback w
        | idx ->
            let msgLen = idx - pos in
            Bigbuffer.add_bigstring buffer
              (Bigstring.sub_shared buf ~pos ~len:msgLen) ;
            Bigbuffer.add_bigstring buffer padding ;
            let contents = Bigbuffer.big_contents buffer in
            let json = Simdjson.loadBuf parser contents in
            Bigbuffer.clear buffer ;
            Pipe.write_without_pushback w json ;
            loop (pos + msgLen + 1) (len - msgLen - 1) in
    loop pos len

  let of_reader ?(parser = Simdjson.createParser ())
      ?(buffer = Bigbuffer.create 4096) r =
    Pipe.create_reader ~close_on_exception:false (fun w ->
        Reader.read_one_chunk_at_a_time r ~handle_chunk:(fun buf ~pos ~len ->
            of_buf parser buffer w buf pos len >>| fun () -> `Continue)
        >>= function
        | `Eof -> Deferred.unit
        | `Eof_with_unconsumed_data _ | `Stopped _ -> assert false)
end

let main r =
  let x = Simdjson.of_reader r in
  Pipe.drain x

let () =
  Command.async ~summary:"Parse ndjson file"
    (let open Command.Let_syntax in
    [%map_open
      let fn = anon ("fn" %: string) in
      fun () -> Reader.with_file fn ~f:main])
  |> Command.run

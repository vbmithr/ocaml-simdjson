open Core
open Async

module Json = struct
  let of_buf bi_outbuf buffer w buf pos len =
    let msg = Bigstring.To_string.sub buf ~pos ~len in
    let rec loop pos len =
      if len <= 0 then Deferred.unit
      else
        match String.index_from msg pos '\n' with
        | None ->
            Buffer.add_substring buffer msg ~pos ~len ;
            Pipe.pushback w
        | Some idx ->
            let msgLen = idx - pos in
            Buffer.add_substring buffer msg ~pos ~len:msgLen ;
            let contents = Buffer.contents buffer in
            Buffer.clear buffer ;
            let json = Yojson.Safe.from_string ~buf:bi_outbuf contents in
            Pipe.write_without_pushback w json ;
            loop (pos + msgLen + 1) (len - msgLen - 1) in
    loop 0 len

  let of_reader ?(bi_outbuf = Bi_outbuf.create 4096)
      ?(buffer = Buffer.create 4096) r =
    Pipe.create_reader ~close_on_exception:false (fun w ->
        Reader.read_one_chunk_at_a_time r ~handle_chunk:(fun buf ~pos ~len ->
            of_buf bi_outbuf buffer w buf pos len >>| fun () -> `Continue)
        >>= function
        | `Eof -> Deferred.unit
        | `Eof_with_unconsumed_data _ | `Stopped _ -> assert false)
end

module JsonFast = struct
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
            let json = Simdjson.parse parser contents in
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

  let of_file ?(parser = Simdjson.createParser ()) fn =
    let d = Simdjson.loadMany parser fn in
    let seq = Simdjson.seqOfDocStream d in
    Pipe.create_reader ~close_on_exception:false (fun w ->
        Seq.iter (Pipe.write_without_pushback_if_open w) seq ;
        Deferred.unit)
end

let simdjson fn =
  let x = JsonFast.of_file fn in
  Pipe.drain x

let yojson r =
  let x = Json.of_reader r in
  Pipe.drain x

let simdjson =
  Command.async ~summary:"Parse ndjson file"
    (let open Command.Let_syntax in
    [%map_open
      let fn = anon ("fn" %: string) in
      fun () -> simdjson fn])

let yojson =
  Command.async ~summary:"Parse ndjson file"
    (let open Command.Let_syntax in
    [%map_open
      let fn = anon ("fn" %: string) in
      fun () -> Reader.with_file fn ~f:yojson])

let () =
  Command.group ~summary:"json bench"
    [("yojson", yojson); ("simdjson", simdjson)]
  |> Command.run

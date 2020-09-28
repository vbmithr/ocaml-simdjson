open Core
open Async

let parse_many ?(sep = '\n') ?(parser = Simdjson.createParser ())
    ?(buflen = 4096) w =
  let bbuf = Bigbuffer.create buflen in
  fun buf ~pos ~len ->
    let rev_find buf pos len =
      let rec loop p =
        if p < 0 then p
        else if Char.equal (Bigstring.get buf (pos + p)) sep then p
        else loop (pred p) in
      loop (pred len) in
    let len' = rev_find buf pos len in
    if len' < 0 then (
      Bigbuffer.add_bigstring bbuf (Bigstring.sub_shared buf ~pos ~len) ;
      Deferred.unit )
    else (
      Bigbuffer.add_bigstring bbuf (Bigstring.sub_shared buf ~pos ~len:len') ;
      let parseLen = Bigbuffer.length bbuf in
      Bigbuffer.add_bigstring bbuf Simdjson.padding ;
      let seq =
        Simdjson.parseMany ~len:parseLen parser
          (Bigbuffer.volatile_contents bbuf)
        |> Simdjson.seqOfDocStream in
      Seq.iter (Pipe.write_without_pushback_if_open w) seq ;
      Pipe.pushback w
      >>| fun () ->
      Bigbuffer.clear bbuf ;
      if len - len' - 1 > 0 then
        Bigbuffer.add_bigstring bbuf
          (Bigstring.sub_shared buf ~pos:(pos + len' + 1) ~len:(len - len' - 1))
      )

let of_reader ?parser ?buflen r =
  Pipe.create_reader ~close_on_exception:true (fun w ->
      let parse = parse_many ?parser ?buflen w in
      let handle_chunk buf ~pos ~len =
        parse buf ~pos ~len >>| fun () -> `Continue in
      Reader.read_one_chunk_at_a_time r ~handle_chunk >>= fun _ -> Deferred.unit)

let of_pipe ?parser ?buflen r =
  Pipe.create_reader ~close_on_exception:true (fun w ->
      let parse = parse_many ?parser ?buflen w in
      Pipe.iter r ~f:(fun (buf, pos, len) -> parse buf ~pos ~len))

let of_file ?batchSize ?(parser = Simdjson.createParser ()) fn =
  let ds = Simdjson.loadMany ?batchSize parser fn in
  let seq = Simdjson.seqOfDocStream ds in
  Pipe.create_reader ~close_on_exception:true (fun w ->
      let rec loop seq =
        match seq () with
        | Seq.Nil -> Deferred.unit
        | Cons (x, seq) -> Pipe.write_if_open w x >>= fun () -> loop seq in
      loop seq)

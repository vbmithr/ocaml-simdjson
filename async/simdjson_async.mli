open Core
open Async

val of_reader :
  ?parser:Simdjson.parser ->
  ?buflen:int ->
  Reader.t ->
  Simdjson.elt Pipe.Reader.t

val of_pipe :
  ?parser:Simdjson.parser ->
  ?buflen:int ->
  (Bigstring.t * int * int) Pipe.Reader.t ->
  Simdjson.elt Pipe.Reader.t

val of_file :
  ?batchSize:int ->
  ?parser:Simdjson.parser ->
  string ->
  Simdjson.elt Pipe.Reader.t

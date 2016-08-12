
module type BENCHMARK = sig
  val time : unit -> float
end

module type READDIR = sig
  type t

  val readdir : string -> t list
end

let path = "../../bigdir"
let expected_length = 4096

module Run(M : READDIR) : BENCHMARK = struct
  let time () =
    let start = Mtime.counter () in
    let listing = M.readdir path in
    let span = Mtime.count start in
    let len = List.length listing in
    assert (len = expected_length || len = expected_length + 2);
    Mtime.to_ms span
end

let run _name modu =
  let count =
    if Array.length Sys.argv > 1
    then int_of_string (Sys.argv.(1))
    else 10
  in
  let module Benchmark = (val modu : BENCHMARK) in
  for i = 0 to count - 1 do
    let f = Benchmark.time () in
    Printf.printf "%f\n" f
  done

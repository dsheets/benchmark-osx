type t = string
open Async.Std
open Async_unix

let readdir p =
  Async_sys.readdir p
  >>= fun listing ->
  return (Array.to_list listing)

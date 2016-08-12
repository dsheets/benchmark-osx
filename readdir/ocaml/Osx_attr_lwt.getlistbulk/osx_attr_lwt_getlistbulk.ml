type t = Osx_attr.Value.t list
open Lwt.Infix

let readdir p =
  Lwt_unix.openfile p [] 0
  >>= fun lwt_fd ->
  let fd = Lwt_unix.unix_file_descr lwt_fd in
  let rec next listing =
    Osx_attr_lwt.getlistbulk Osx_attr_getlistbulk.type_and_id fd
    >>= function
    | [] -> Lwt.return listing
    | more -> next (List.rev_append more listing)
  in
  next []
  >>= fun listing ->
  Lwt_unix.close lwt_fd
  >>= fun () ->
  Lwt.return listing

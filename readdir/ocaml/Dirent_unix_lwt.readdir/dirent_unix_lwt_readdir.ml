type t = Dirent.Dirent.t
open Lwt.Infix

let readdir p =
  Dirent_unix_lwt.opendir p
  >>= fun dh ->
  let rec next listing =
    Lwt.catch
      (fun () -> Dirent_unix_lwt.readdir dh >>= Lwt.return_some)
      (function End_of_file -> Lwt.return_none | exn -> Lwt.fail exn)
    >>= function
    | Some dirent -> next (dirent::listing)
    | None -> Lwt.return listing
  in
  next []
  >>= fun listing ->
  Dirent_unix_lwt.closedir dh
  >>= fun () ->
  Lwt.return listing

type t = Dirent.Dirent.t

let readdir p =
  let dh = Dirent_unix.opendir p in
  let rec next listing =
    match Dirent_unix.readdir dh with
    | exception End_of_file -> listing
    | dirent -> next (dirent::listing)
  in
  let listing = next [] in
  Dirent_unix.closedir dh;
  listing

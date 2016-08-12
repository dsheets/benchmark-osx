type t = string

let readdir p =
  let dh = Unix.opendir p in
  let rec next listing =
    match Unix.readdir dh with
    | exception End_of_file -> listing
    | dirent -> next (dirent::listing)
  in
  let listing = next [] in
  Unix.closedir dh;
  listing

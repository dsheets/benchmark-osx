type t = string

let readdir p =
  let listing = Sys.readdir p in
  Array.to_list listing

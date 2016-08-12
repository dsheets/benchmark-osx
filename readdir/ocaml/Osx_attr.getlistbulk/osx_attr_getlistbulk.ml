type t = Osx_attr.Value.t list

let type_and_id = Osx_attr.(Query.[
  Common Common.OBJTYPE;
  Common Common.FILEID;
])

let readdir p =
  let fd = Unix.openfile p [] 0 in
  let rec next listing =
    match Osx_attr.(getlistbulk type_and_id fd) with
    | [] -> listing
    | more -> next (List.rev_append more listing)
  in
  let listing = next [] in
  Unix.close fd;
  listing

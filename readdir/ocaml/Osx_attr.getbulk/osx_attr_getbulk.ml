type t = string * Osx_attr.Vnode.Vtype.t option

let readdir p =
  let fd = Unix.openfile p [] 0 in
  let rec next listing =
    match Osx_attr.(getbulk (Select.Common Common.OBJTYPE) fd) with
    | [] -> listing
    | more -> next (List.rev_append more listing)
  in
  let listing = next [] in
  Unix.close fd;
  listing

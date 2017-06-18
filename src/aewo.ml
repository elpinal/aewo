let usage () =
  "All Emacs is Well Ordered.\n\
   \n\
   usage:
   aewo command arguments...\n\
   \n\
   commands:
   install      Install a specified version of Emacs.
   uninstall    Uninstall a specified version of Emacs.
   use          Set a specified version of Emacs as current program.
   list         List versions.
   " |> print_endline

let root = Filename.concat (Sys.getenv "HOME") ".aewo"

let default_uri = "git://git.savannah.gnu.org/emacs.git"

module Exec = struct
  let with_dir dir cmd args =
    let open Unix in
    let pid = Unix.fork () in
    if pid == 0 then (
      Unix.chdir dir;
      Unix.execvp cmd @@ Array.append [|cmd|] args
    ) else
      match snd (Unix.waitpid [] pid) with
      | WEXITED 0 -> ()
      | WEXITED code -> failwith @@ Printf.sprintf "%s exited with code: %d" cmd code
      | WSIGNALED signal -> failwith @@ Printf.sprintf "%s was killed with signal: %d" cmd signal
      | WSTOPPED signal -> failwith @@ Printf.sprintf "%s was stopped with signal: %d" cmd signal

  let exec = with_dir @@ Unix.getcwd ()
end

let ensure_dir dirname =
  if not @@ Sys.file_exists dirname then
    Unix.mkdir dirname 0o777

let init uri =
  if not @@ Sys.file_exists root then (
    Unix.mkdir root 0o777;
    Exec.exec "git" [| "clone"; "--mirror"; uri; Filename.concat root "repo" |]
  )

let checkout version =
  let versions = Filename.concat root "emacs" in
  ensure_dir versions;
  let dir = Filename.concat versions version in
  Exec.exec "git" [| "clone"; Filename.concat root "repo"; dir |];
  Exec.with_dir dir "git" [| "reset"; "--hard"; version |]

let uncurry f = fun (x, y) -> f x y

let build version =
  let dir = List.fold_left Filename.concat "" [root; "emacs"; version] in
  List.iter (uncurry @@ Exec.with_dir dir) [ "./autogen.sh", [||]
                                           ; "./configure", [| "--without-ns"; "--without-x" |]
                                           ; "make", [| "-k"; "-j4" |]
                                           ]

let is_symlink x =
  let open Unix in
  let stats = lstat x in
  stats.st_kind == S_LNK

let link version =
  let src = List.fold_left Filename.concat "" [root; "emacs"; version; "src/emacs"] in
  if not @@ Sys.file_exists src then (
    Printf.sprintf "linking %s: executable does not exist" version |> prerr_endline; exit 1
  );
  let bin_dir = Filename.concat root "bin" in
  ensure_dir bin_dir;
  let dest = Filename.concat bin_dir "emacs" in
  (* If dest is symlink, Sys.file_exists does not return true. So, || is used, not &&. *)
  if Sys.file_exists dest || is_symlink dest then
    Sys.remove dest;
  Unix.symlink src dest

let install = function
  | None -> "install: version should be given" |> prerr_endline; exit 1
  | Some version ->
     init default_uri; (* update; *)
     checkout version;
     build version;
     link version

let uninstall = function
  | None -> prerr_endline "uninstall: version should be givin";exit 1
  | Some version ->
     try Sys.remove @@ List.fold_left Filename.concat "" [root; "emacs"; version] with
     | Sys_error msg -> prerr_endline @@ Printf.sprintf "remove %S: %s" version msg; exit 1

let use = function
  | None -> "use: version should be given" |> prerr_endline; exit 1
  | Some version -> link version

let twice f x = f @@ f x

let print_item version =
  let linked = Unix.readlink @@ List.fold_left Filename.concat "" [root; "bin"; "emacs"] in
  let current = Filename.basename @@ twice Filename.dirname linked in
  if version = current then
    print_endline @@ "* " ^ version
  else
    print_endline @@ "  " ^ version

let list = function
  | None -> Array.iter print_item @@ Sys.readdir @@ Filename.concat root "emacs"
  | _ -> "usage: list" |> prerr_endline; exit 1

let run = function
  | "install" -> install
  | "uninstall" -> uninstall
  | "use" -> use
  | "list" -> list
  | name -> "no such command: " ^ name |> prerr_endline; exit 1

let at n = function
  | [||] -> None
  | a -> if 0 <= n && n < Array.length a then Some a.(n)
         else None

let () =
  if Array.length Sys.argv == 1 then usage ()
  else run Sys.argv.(1) @@ at 2 Sys.argv

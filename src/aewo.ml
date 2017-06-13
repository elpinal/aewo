let usage () =
        "All Emacs is Well Ordered.\n\
         \n\
         usage:
         aewo command arguments...\n\
         \n\
         commands:
         install      Install a specified version of Emacs.
         uninstall    Uninstall a specified version of Emacs.
         " |> print_endline;;

let root = Filename.concat (Sys.getenv "HOME") ".aewo";;

let defaultURI = "git://git.savannah.gnu.org/emacs.git";;

(* Exec *)

(* TODO: exit on error *)
let execDir dir cmd args =
        let pid = Unix.fork () in
                if pid == 0 then (
                        Unix.chdir dir;
                        Unix.execvp cmd (Array.append [|cmd|] args))
                else
                        Unix.waitpid [] pid

let exec = execDir (Unix.getcwd ())

(* Main *)

let ensureDir dirname =
        if not (Sys.file_exists dirname) then
                Unix.mkdir dirname 0o777

let init uri =
        if not (Sys.file_exists root) then (
                Unix.mkdir root 0o777;
                exec "git" [| "clone"; "--mirror"; uri; (Filename.concat root "repo") |];
                ())

let checkout version =
        ensureDir (Filename.concat root "emacs");
        let dir =
                (Filename.concat (Filename.concat root "emacs") version)
        in
        exec "git" [| "clone"; (Filename.concat root "repo"); dir |];
        execDir dir "git" [| "reset"; "--hard"; version |]

let build version =
        let dir =
                (Filename.concat (Filename.concat root "emacs") version)
        in
        execDir dir "./autogen.sh" [||];
        execDir dir "./configure" [| "--without-ns"; "--without-x" |];
        execDir dir "make" [| "-k"; "-j4" |]

let is_symlink x =
        let open Unix
        in
        let stats = lstat x
        in
        stats.st_kind == S_LNK

let link version =
        let src =
                (Filename.concat (Filename.concat (Filename.concat root "emacs") version) "src/emacs")
        in
        if not (Sys.file_exists src) then
                (Printf.sprintf "linking %s: executable does not exist" version |> prerr_endline; exit 1);
        ensureDir (Filename.concat root "bin");
        let dest = (Filename.concat root "bin/emacs")
        in
        (* If dest is symlink, Sys.file_exists does not return true. So, || is used, not &&. *)
        if (Sys.file_exists dest) || (is_symlink dest) then
                Sys.remove dest;
        Unix.symlink src dest

let install = function
        | None -> "install: version should be given" |> prerr_endline; exit 1
        | Some version -> (
                init defaultURI; (* update; *)
                checkout version;
                build version;
                link version;
                ())

(* TODO: implement this *)
let uninstall version = ()

let use = function
        | None -> "use: version should be given" |> prerr_endline; exit 1
        | Some version -> link version

let run = function
        | "install" -> install
        | "uninstall" -> uninstall
        | "use" -> use
        | name -> "no such command: " ^ name |> prerr_endline; exit 1

let at n = function
        | [||] -> None
        | a -> if 0 <= n && n < Array.length a then Some a.(n)
               else None

let () =
        if Array.length Sys.argv == 1 then usage ()
        else run Sys.argv.(1) (at 2 Sys.argv)

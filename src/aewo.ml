let usage () =
        "All Emacs is Well Ordered.\n\
         usage:
         aewo command arguments...\n\
         \n\
         commands:
         install      Install a specified version of Emacs.
         uninstall    Uninstall a specified version of Emacs.
         " |> print_endline;;

let run = function
        | "install" -> "installing..." |> print_endline
        | "uninstall" -> "uninstalling..." |> print_endline
        | name -> "no such command: " ^ name |> prerr_endline; exit 1

let () =
        if Array.length Sys.argv == 1 then usage ()
        else run Sys.argv.(1)

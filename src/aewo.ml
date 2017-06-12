let usage () =
        "All Emacs is Well Ordered.\n\
         usage:
         aewo command arguments...\n\
         \n\
         commands:
         install      Install a specified version of Emacs.
         uninstall    Uninstall a specified version of Emacs.
         " |> print_endline;;

let () = usage ();;

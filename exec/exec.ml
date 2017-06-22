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

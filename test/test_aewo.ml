open OUnit2

let test_aewo test_ctxt = assert_equal () @@ Exec.exec "echo" [|"aewo"|]

let suite =
  "suite" >:::
    ["aewo" >:: test_aewo]

let () = run_test_tt_main suite

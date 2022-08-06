(** This module tests the PPX with Alcotest *)

open Alcotest

module Bool_map = Map.Make(Bool)
module Int_map = Map.Make(Int)

module type DUMMY = sig end
module D : DUMMY = struct end
module M (X : DUMMY) = struct include Int end

(** A check for empty maps *)
let test_empty () =
  check int "can initialize empty maps" 0 (Int_map.cardinal [%map Int])

(** A check for single element maps *)
let test_single () =
  let i = 0 in
  check int "can initialize explicitely typed maps" 1 (Int_map.cardinal [%map Int; i => 10]);
  check int "can initialize implicitely typed maps" 1 (Int_map.cardinal [%map 0 => 10])

(** A check for repeated values *)
let test_repeated () =
  let map = [%map 1 => 11; 2 => 12; 3 => 13; 2 => 102; 1 => 101] in
  check int "only keeps the last values" 101 (Int_map.find 1 map);
  check int "only keeps the last values" 102 (Int_map.find 2 map)

(** A check for map equality *)
let test_equality () =
  check bool "equal" true (Bool_map.equal (=) [%map true => 1; false => 0]
                                              [%map false => 0; true => 1])

(** A compile-time check for simple type inference *)
let test_inference () =
  ignore ([%map true => 1; false => 0], [%map false => 0; true => 1], [%map 'F' => 0; 'T' => 1],
          [%map 0. => 0; 1. => 1], [%map 0 => 0; 1 => 1], [%map "false" => 0; "true" => 1],
          [%map () => 0]);
  check bool "type checks" true true

(** A compile-time check for explicit typing using a functor *)
let test_functor () =
  ignore [%map M (D); 0 => 1; 1 => 2];
  check bool "type checks" true true

let tests = [
  ("test_empty", `Quick, test_empty);
  ("test_single", `Quick, test_single);
  ("test_repeated", `Quick, test_repeated);
  ("test_equality", `Quick, test_equality);
  ("test_inference", `Quick, test_inference);
  ("test_functor", `Quick, test_functor)
]

let test_suites: unit test list = [
  "Catch", tests;
]

(** Run the test suites *)
let () = run "ppx_map" test_suites

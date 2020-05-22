(*
 * Copyright (C) Citrix Systems Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)

module Generic = struct
  module type IO = sig
    (* The type of inputs to a system being tested. *)
    type input_t

    (* The type of outputs from a system being tested. *)
    type output_t

    (* Helper functions for printing error messages on test failure. *)
    val string_of_input_t : input_t -> string

    val string_of_output_t : output_t -> string
  end

  module type STATE = sig
    (* The type of system state, which will be modified by inputs to the system. *)
    type state_t

    (* Create a base system state. *)
    val create_default_state : unit -> state_t
  end

  module type STATELESS_TEST = sig
    module Io : IO

    (* A function to transform an input into an output. *)
    val transform : Io.input_t -> Io.output_t

    (* A list of input/output pairs. *)
    val tests :
      [> `Documented of
         (string * Alcotest.speed_level * Io.input_t * Io.output_t) list
      | `QuickAndAutoDocumented of (Io.input_t * Io.output_t) list ]
  end

  module type STATEFUL_TEST = sig
    module Io : IO

    module State : STATE

    (* A function to apply an input to the system state. *)
    val load_input : State.state_t -> Io.input_t -> unit

    (* A function to extract an output from the system state. How this is done
       		 * may depend on the input to the test. *)
    val extract_output : State.state_t -> Io.input_t -> Io.output_t

    (* A list of input/output pairs. *)
    val tests :
      [> `Documented of
         (string * Alcotest.speed_level * Io.input_t * Io.output_t) list
      | `QuickAndAutoDocumented of (Io.input_t * Io.output_t) list ]
  end

  (* Turn a stateful test module into a stateless test module. *)
  module EncapsulateState (T : STATEFUL_TEST) = struct
    module Io = T.Io

    let transform input =
      let state = T.State.create_default_state () in
      T.load_input state input ;
      T.extract_output state input

    let tests = T.tests
  end

  module MakeStateless (T : STATELESS_TEST) : sig
    val tests : unit Alcotest.test_case list
  end = struct
    let title input expected_output =
      Printf.sprintf "%s -> %s"
        (T.Io.string_of_input_t input)
        (T.Io.string_of_output_t expected_output)
      |> String.trim

    let prune_if_too_long s idx =
      let max_size = 70 in
      let len = String.length s in
      if len <= max_size then
        s
      else
        let template = Format.sprintf "%d: %s...%s" idx in
        let slice_len = (max_size - String.length (template "" "")) / 2 in
        template (String.sub s 0 slice_len)
          (String.sub s (len - slice_len - 1) slice_len)

    let test_equal ~input ~expected_output () =
      let alco_testable =
        Test_util.alcotestable_of_pp T.Io.string_of_output_t
      in
      Alcotest.check alco_testable
        (title input expected_output)
        expected_output (T.transform input)

    let tests =
      match T.tests with
      | `Documented ts ->
          List.map
            (fun (doc_str, speed, input, expected_output) ->
              (doc_str, speed, test_equal ~input ~expected_output))
            ts
      | `QuickAndAutoDocumented ts ->
          List.mapi
            (fun idx (input, expected_output) ->
              let doc_str =
                prune_if_too_long (title input expected_output) idx
              in
              (doc_str, `Quick, test_equal ~input ~expected_output))
            ts
  end

  module MakeStateful (T : STATEFUL_TEST) : sig
    val tests : unit Alcotest.test_case list
  end =
    MakeStateless (EncapsulateState (T))
end

let make_suite prefix =
  List.map (fun (s, t) -> (Format.sprintf "%s%s" prefix s, t))

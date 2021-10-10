(* Copyright (C) 2017--2021  Petter A. Urkedal <paurkedal@gmail.com>
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version, with the LGPL-3.0 Linking Exception.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * and the LGPL-3.0 Linking Exception along with this library.  If not, see
 * <http://www.gnu.org/licenses/> and <https://spdx.org>, respectively.
 *)

open Printf

(* These two should produce the same code when run though dumpast: *)

let stringify =
  List.map (string_of_int % fst)
    %> String.concat ";"
    %> sprintf "[%s]"

let stringify' xs =
  sprintf "[%s]"
    (String.concat ";"
      (List.map (fun x -> string_of_int (fst x)) xs))

let apply f x = f x

let () = assert (stringify [17, "a"; 20, "b"; 36, "c"] = "[17;20;36]")

let () =
  let open Compose in
  let double_succ = apply (%) (( * ) 2) succ in
  let succ_double = apply (%>) (( * ) 2) succ in
  assert (double_succ 12 = 26);
  assert (succ_double 12 = 25);
  let post_succ = (%) succ in
  let succ_abs = post_succ abs in
  assert (succ_abs (-12) = 13)

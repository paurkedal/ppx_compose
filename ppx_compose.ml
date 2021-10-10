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

open Ppxlib
open Ast_builder.Default

(* Is there an existing function? *)
let fresh_var_for e =
  Printf.sprintf "_ppx_compose_%d" e.pexp_loc.Location.loc_start.Lexing.pos_cnum

let apply ~loc f xs =
  (match f.pexp_desc with
   | Pexp_apply (f', xs') ->
      pexp_apply ~loc f' (List.append xs' xs)
   | _ ->
      pexp_apply ~loc f xs)

let rec reduce_compose h x =
  (match h.pexp_desc with
   | Pexp_apply ({pexp_desc = Pexp_ident {txt = Lident "%"; _}; _},
                 [(Nolabel, g); (Nolabel, f)])
   | Pexp_apply ({pexp_desc = Pexp_ident {txt = Lident "%>"; _}; _},
                 [(Nolabel, f); (Nolabel, g)]) ->
      let fx = reduce_compose f x in
      reduce_compose g fx
   | _ ->
      (apply ~loc:h.pexp_loc h [Nolabel, x]))

let classify e =
  (match e.pexp_desc with
   | Pexp_apply ({pexp_desc = Pexp_ident {txt = Lident "%"; _}; _},
                 [(Nolabel, _); (Nolabel, _)]) -> `Compose
   | Pexp_apply ({pexp_desc = Pexp_ident {txt = Lident "%>"; _}; _},
                 [(Nolabel, _); (Nolabel, _)]) -> `Compose_fw
   | _ -> `Other)

let eta_expand_composition ~is_fw e =
  let name = fresh_var_for e in
  let var_loc =
    if is_fw then {e.pexp_loc with loc_end = e.pexp_loc.loc_start}
             else {e.pexp_loc with loc_start = e.pexp_loc.loc_end} in
  let pat = ppat_var ~loc:var_loc {txt = name; loc = var_loc} in
  let arg = pexp_ident ~loc:var_loc {txt = Lident name; loc = var_loc} in
  let body = reduce_compose e arg in
  pexp_fun ~loc:e.pexp_loc Nolabel None pat body

let rewrite_compose e =
  (match e.pexp_desc with
   | Pexp_apply (h, ((Nolabel, x) :: xs)) when classify h <> `Other ->
      Some (apply ~loc:e.pexp_loc (reduce_compose h x) xs)
   | _ ->
      (match classify e with
       | `Compose -> Some (eta_expand_composition ~is_fw:false e)
       | `Compose_fw -> Some (eta_expand_composition ~is_fw:true e)
       | `Other -> None))

let rules = [
  Context_free.Rule.special_function "%" rewrite_compose;
  Context_free.Rule.special_function "%>" rewrite_compose;
]

let () = Driver.register_transformation ~rules "ppx_compose"

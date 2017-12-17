(* Copyright (C) 2017  Petter A. Urkedal <paurkedal@gmail.com>
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version, with the OCaml static compilation exception.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *)

open Migrate_parsetree
open Ast_404
let ocaml_version = Versions.ocaml_404

open Ast_mapper
open Ast_helper
open Asttypes
open Parsetree
open Longident

(* Is there an existing function? *)
let fresh_var_for e =
  Printf.sprintf "_ppx_compose_%d" e.pexp_loc.Location.loc_start.Lexing.pos_cnum

let apply ~loc f xs =
  (match f.pexp_desc with
   | Pexp_apply (f', xs') ->
      Exp.apply ~loc f' (List.append xs' xs)
   | _ ->
      Exp.apply ~loc f xs)

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

let is_composition e =
  (match e.pexp_desc with
   | Pexp_apply ({pexp_desc = Pexp_ident {txt = Lident ("%" | "%>"); _}; _},
                 [(Nolabel, _); (Nolabel, _)]) -> true
   | _ -> false)

let rewrite_expr mapper e =
  (match e.pexp_desc with
   | Pexp_apply (h, ((Nolabel, x) :: xs)) when is_composition h ->
      mapper.expr mapper (apply ~loc:e.pexp_loc (reduce_compose h x) xs)
   | _ ->
      if is_composition e then
        let name = fresh_var_for e in
        let pat = Pat.var ~loc:e.pexp_loc {txt = name; loc = e.pexp_loc} in
        let lid = {txt = Lident name; loc = e.pexp_loc} in
        let arg = Exp.ident ~loc:e.pexp_loc lid in
        let body = mapper.expr mapper (reduce_compose e arg) in
        Exp.fun_ ~loc:e.pexp_loc Nolabel None pat body
      else
        default_mapper.expr mapper e)

let compose_mapper _config _cookies = {default_mapper with expr = rewrite_expr}

let () = Driver.register ~name:"ppx_compose" ocaml_version compose_mapper

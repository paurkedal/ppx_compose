#! /usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let licenses = List.map Pkg.std_file ["COPYING.LESSER"; "COPYING"]

(* Linting of META disabled due to presumed spurious complaints about the
 * ppx_driver predicate in the plugin assignments. *)
let metas = [Pkg.meta_file ~lint:false "pkg/META"]

let () = Pkg.describe ~licenses ~metas "ppx_compose" @@ fun c ->
  Ok [
    Pkg.lib "ppx_compose.cmo";
    Pkg.lib "ppx_compose.cmx";
    Pkg.lib "ppx_compose.o";
    Pkg.libexec ~dst:"ppx_compose" "ppx_compose_main";
    Pkg.mllib "ppx_compose_runtime.mllib";
    Pkg.test "test_compose";
  ]

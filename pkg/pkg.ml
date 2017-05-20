#! /usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let licenses = List.map Pkg.std_file ["COPYING.LESSER"; "COPYING"]

let () = Pkg.describe ~licenses "ppx_compose" @@ fun c ->
  Ok [
    Pkg.lib "ppx_compose.cmo";
    Pkg.lib "ppx_compose.cmx";
    Pkg.lib "ppx_compose.o";
    Pkg.libexec ~dst:"ppx_compose" "ppx_compose_main";
    Pkg.test "test_compose";
  ]

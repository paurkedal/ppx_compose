#! /usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let licenses = List.map Pkg.std_file ["COPYING.LESSER"; "COPYING"]

let () = Pkg.describe ~licenses "ppx_compose" @@ fun c ->
  Ok [
    Pkg.libexec "ppx_compose";
    Pkg.test "test_compose";
  ]

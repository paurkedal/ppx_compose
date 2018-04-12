#! /bin/sh
set -e
cd `dirname $0`/..
opam pin add -yn ppx_compose .
opam depext -y ppx_compose
opam install -yt ppx_compose

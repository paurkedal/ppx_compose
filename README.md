# `ppx_compose` - Composition Inlining for OCaml

## Synopsis

This is a very simple syntax extension which rewrites code containing
compositions into composition-free code, effectively inlining the
composition operators.  The following two operators are supported
```ocaml
let (%) g f x = g (f x)
let (%>) f g x = g (f x)
```
These definitions are not provided, so partial applications of `(%)` and
`(%>)` will be undefined unless you provide the definitions.

The following rewrites are done:

  * A composition occurring to the left of an application is reduced by
    applying each term of the composition from right to left to the
    argument, ignoring associative variations.

  * A composition which is not the left side of an application is first
    turned into one by η-expansion, then the above rule applies.

  * Any partially applied composition operators are passed though unchanged.

E.g.
```ocaml
h % g % f ==> (fun x -> h (f (g x)))
h % (g % f) ==> (fun x -> h (f (g x)))
(g % f) (h % h) ==> g (f (fun x -> h (h x)))
```

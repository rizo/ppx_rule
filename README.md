
# Compile-time optimization rules

This syntax extension implements compile-time rewrite rules to offer a powerful and flexible way to optimise your program.

Consider the folloring simple examples:

```ocaml
(* Helper functions *)

let sum x y = x + y
let hello who = "Hello, " ^ who

(* Rules *)

let%rule sum 2 2 = 5
let%rule hello "rule" = "rules rock!"
let%rule sqrt 100000000000.0 = 316227.766017

let replaced = (sum 2 2, hello "rule", sqrt 100000000000.0)
let computed = (sum 1 1, hello "world", sqrt 99.0)
```

The syntax processor will replace the known patterns during the compilation time.  
After the application the resulting code will look like this:

```ocaml
let sum x y = x + y
let hello who = "Hello, " ^ who

let replaced = (0, "rules rock!", 316227.766017)
let computed = (sum 1 1, hello "world", sqrt 99.0)
```

Note that the rules disappear during the compliation, so no runtime overhead is added to the program.

For more examples see the `tests` directory and for build options run `make help`.

This project is still in development, please use with care.

This syntax extension was inspired by [Rule pragma](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/rewrite-rules.html) for Haskell.


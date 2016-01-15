
(* Helper functions *)

let sum x y = x + y

let hello ~name = "Hello, " ^ name

let rec factorial n =
  if n = 0 then 1 else n * factorial (n - 1)

(* Constant value rules. *)

(* let%rule number = 42 *)

(* Simple functions. *)

let%rule sum 2 2 = 4
let%rule sum' 2 = fun 2 -> 4
let%rule sum'' = fun 2 -> fun 2 -> 4

(* Labeled functions. *)

let%rule hello ~name:"world" = "Good bye, world"

(* Case functions. *)

let%rule sin 1.0 = 0.841470984808
let%rule sqrt = function 100.0 -> 10.0 | 10000.0 -> 100.0
let%rule factorial = function
  | 24 -> 1388186055525531648
  | n when n > 24 -> raise (Failure "factorial: overflow")
let%rule sum' = fun 2 -> function 2 -> 2
                               | 3 -> 5

let tests = begin
  (* number, *)
  sin 1.0,
  sin 0.5,
  sum 2 2,
  sqrt 100.0
end


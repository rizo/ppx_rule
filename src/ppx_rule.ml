
open Ast_mapper
open Asttypes
open Parsetree

let log str = output_string stderr (str ^ "\n")

(* TODO: Review this documentation, more combinations are possible. *)
(* Recursively rocesses the value binding expression collecting patterns and
   values. Two types of bindings are possible: One and Many.

   The "One" binding results from Pexp_fun usage. In this case the return value
   will contain a list of consecutive lambda patterns and the final value:

       fun pat0 -> fun pat1 -> ... -> patN -> val

       `One ([pat0; pat1; ...; patN], val)

   The "Many" bindings are created with Pexp_function in which case several
   patterns and values are collected:

       function
       | pat0 -> val0
       | pat1 -> val1
       ...
       | patN -> valN

       `Many [(pat0, val0); (pat1, val1); ...; (patN, valN)]

   The Pexp_fun rules with labels and optional arguments are not supported.
   The Pexp_function rules with when conditions are not supported.
   *)
let collect_bindings expr =
  let rec loop (pat_list, _) expr =
    match expr with
    | Pexp_fun ("", None, {ppat_desc = pat}, {pexp_desc = next}) ->
      loop (pat :: pat_list, None) next

    | Pexp_fun (label, None, {ppat_desc = pat}, next) ->
      failwith "[%%rule]: rules with labels are not currently supported"

    | Pexp_fun (_, Some default_arg, _, _) ->
      failwith "[%%rule]: rules with optional arguments are illegal"

    | Pexp_function case_list ->
      failwith "[%%rule]: rules with multiple cases are not currently supported"

    (* Everything else is expected to be a value. *)
    | value -> (pat_list, Some value)
  in
  match loop ([], None) expr with
  | pat_list, Some value -> pat_list, value
  | _ -> assert false

let rule_of_binding {pvb_pat; pvb_expr} =
  match pvb_pat with
  | {ppat_desc = Ppat_var {txt = rule_name}} ->
    let (pat_list, value) = collect_bindings pvb_expr.pexp_desc in
    (rule_name, pat_list, value)
  | _ -> failwith "FIXME"

let exp_to_pat_equiv exp =
  match exp with
  | Pexp_constant x -> Some (Ppat_constant x)
  | _ -> None

let find_rule_for_call rules (func_name, arg_exp_list) =
  let pat_opt_list = List.map exp_to_pat_equiv arg_exp_list in
  let all_pat_ok = List.for_all
      (function Some _ -> true | None -> false) pat_opt_list in

  if not all_pat_ok then None
  else
    let pat_list = List.map
        (function Some x -> x | None -> assert false) pat_opt_list in
    if Hashtbl.mem rules (func_name, pat_list) then
      Some (Hashtbl.find rules (func_name, pat_list))
    else None

let rules_table = Hashtbl.create 100

let rec structure mapper items =
  match items with
  (*
   * Register rewrite rule: `let%rule f x = value`
   *)
  | {pstr_desc =
       Pstr_extension (({txt = "rule"; loc}, PStr [{pstr_desc =
         Pstr_value (_rec_flag, value_binding_list)}]), _)} :: items ->
    (* - extract info from payload: rule name and args *)
    let rules =
      try List.map rule_of_binding value_binding_list
      with Failure msg ->
        log ("e: " ^ msg);
        [] in
    (* - register the rule in the hashtable with metadata (TODO: loc) *)
    let () = List.iter (fun (pat_name, pat_list, value) ->
        log ("i: saving rule " ^ pat_name);
        Hashtbl.add rules_table (pat_name, pat_list) value) rules in
    (* - skip this item, return items *)
    structure mapper items

  | item :: items ->
    mapper.structure_item mapper item :: structure mapper items

  | [] -> []

let expr this e =
  match e.pexp_desc with
  (*
   * Apply rewrite rule: `f x...` -> `value`
   *)
  | Pexp_apply ({pexp_desc = Pexp_ident {txt = Longident.Lident func_name}}, args) ->
    let arg_exp_list = List.map (fun (l, {pexp_desc = exp}) -> exp) args in
    begin match find_rule_for_call rules_table (func_name, arg_exp_list) with
      | Some value -> { e with pexp_desc = value }
      | None -> e
    end

  | _ -> default_mapper.expr this e

let () =
  Ast_mapper.register "ppx_rule" (fun argv ->
      { default_mapper with structure; expr })


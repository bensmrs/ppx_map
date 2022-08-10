(** This module implements the PPX *)

open Ppxlib
open Ast_builder.Default

(** Convert constructs to modules in the AST *)
let rec pmod_of_pexp_construct ~loc = function
  | Pexp_construct (construct, None) -> pmod_ident ~loc construct
  | Pexp_construct (construct, Some { pexp_desc = Pexp_construct ({ txt = Lident "()"; _ }, None);
                                      pexp_loc; _ }) ->
      pmod_apply ~loc (pmod_ident ~loc construct) (pmod_structure ~loc:pexp_loc [])
  | Pexp_construct (construct, Some { pexp_desc; pexp_loc; _ }) ->
      pmod_apply ~loc (pmod_ident ~loc construct) (pmod_of_pexp_construct ~loc:pexp_loc pexp_desc)
  | _ -> Location.raise_errorf ~loc "Cannot convert this expression into a module application"

(** Extracts the relevant data from [key => value] expressions *)
let process_expr { pexp_desc; pexp_loc = loc; _ } =
  match pexp_desc with
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Lident "=>"; _ }; _ },
                (Nolabel, lhs)::(Nolabel, rhs)::[]) ->
      (loc, lhs, rhs)
  | _ -> Location.raise_errorf ~loc "Expected `key => value' expression"

let empty_map loc = pexp_ident ~loc (Loc.make ~loc (Ldot (Lident "$Map", "empty")))

(** Build the map data expression *)
let make_map ~loc acc seq =
  let rec make_map_data acc = function
    | { pexp_desc = Pexp_sequence (expr, seq); _ } -> make_map_data (process_expr expr::acc) seq
    | expr -> process_expr expr::acc in
  let make_map_instruction acc (loc, lhs, rhs) =
    (pexp_apply ~loc (pexp_ident ~loc (Loc.make ~loc (Ldot (Lident "$Map", "add"))))
                [(Nolabel, lhs); (Nolabel, rhs); (Nolabel, acc)]) in
  let map_data = match seq with
    | Some seq -> List.rev (make_map_data acc seq)
    | None -> acc in
  List.fold_left make_map_instruction (empty_map loc) map_data

(** Format the final expression *)
let letmodule ~loc m expr =
  pexp_letmodule ~loc (Loc.make ~loc (Some "$Map"))
                 (pmod_apply ~loc (pmod_ident ~loc (Loc.make ~loc (Ldot (Lident "Map", "Make")))) m)
                 expr

(** Create a module identifier *)
let pmod_of_longident ~loc name = pmod_ident ~loc (Loc.make ~loc name)

(** Infer the type of the given expression *)
let pmod_of_lhs ~loc lhs =
  pmod_of_longident ~loc (Lident begin match lhs with
    | Pexp_construct ({ txt = Lident "false" | Lident "true"; _ }, None) -> "Bool"
    | Pexp_constant (Pconst_char _) -> "Char"
    | Pexp_constant (Pconst_float _) -> "Float"
    | Pexp_constant (Pconst_integer _) -> "Int"
    | Pexp_constant (Pconst_string _) -> "String"
    | Pexp_construct ({ txt = Lident "()"; _ }, None) -> "Unit"
    | _ -> Location.raise_errorf ~loc "`map' cannot infer the type of this value. You need to give \
                                       an explicit bool, char, float, int, string or unit."
  end)

(** Dispatch to the type inferer and map builder *)
let process_sequence ~loc ({ pexp_desc; pexp_loc = loc'; _ } as expr) seq =
  match pexp_desc with
  | Pexp_construct _ ->
      letmodule ~loc:loc' (pmod_of_pexp_construct ~loc:loc' pexp_desc) (make_map ~loc [] seq)
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Lident "=>"; _ }; _ },
                (Nolabel, { pexp_desc; pexp_loc; _ })::_::[]) ->
      letmodule ~loc:loc' (pmod_of_lhs ~loc:pexp_loc pexp_desc)
                          (make_map ~loc [process_expr expr] seq)
  | _ -> Location.raise_errorf ~loc "`map' requires an optional module followed by \
                                     `key => value' expressions"

(** Normalize the acceptable map formats *)
let process ~loc ~arg structure =
  match arg with
  | Some { txt; loc = loc' } ->
      letmodule ~loc:loc' (pmod_of_longident ~loc:loc' txt) (make_map ~loc [] (match structure with
        | { pstr_desc = Pstr_eval (expr, _); _ }::[] -> Some expr
        | [] -> None
        | _ -> Location.raise_errorf ~loc "`map' cannot parse this map structure"))
  | None -> begin match structure with
      | { pstr_desc = Pstr_eval ({ pexp_desc = Pexp_sequence (expr, seq); _ }, _); _ }::[] ->
          process_sequence ~loc expr (Some seq)
      | { pstr_desc = Pstr_eval (expr, _); _ }::[] -> process_sequence ~loc expr None
      | [] -> Location.raise_errorf ~loc "`map' requires an explicit type when defining empty maps"
      | _ -> Location.raise_errorf ~loc "`map' cannot parse this map structure"
    end

(** Declare the [map] extension *)
let mapper =
  Extension.declare_with_path_arg "map" Extension.Context.expression
    Ast_pattern.(pstr __)
    (fun ~loc ~path:_ ~arg -> process ~loc ~arg)

(** Register the transformation *)
let () = Driver.register_transformation "map" ~extensions:[mapper]

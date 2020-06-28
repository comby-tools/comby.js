open Base

open Match
open Language

let line_map source =
  let total_len = String.length source in
  let num_lines = List.length @@ String.split_on_chars source ~on:['\n'] in
  let a = Array.create ~len:num_lines (Int.max_value) in
  let line_index = ref 0 in
  let f sum char =
    match char with
    | '\n' ->
      a.(!line_index) <- sum + 1;
      line_index := !line_index + 1;
      sum + 1
    | _ ->
      if sum = total_len - 1 then
        begin
          a.(!line_index) <- sum + 1;
          sum + 1
        end
      else
        sum + 1
  in
  let _ = String.fold source ~init:0 ~f in
  a

let rec binary_search a value low high =
  if high <= low then
    low
  else let mid = (low + high) / 2 in
    if a.(mid) > value then
      binary_search a value low (mid - 1)
    else if a.(mid) < value then
      binary_search a value (mid + 1) high
    else
      mid

let compute_line_col_fast a offset =
  let offset = offset - 1 in (* make offset 0-based because line_map is 0-based *)
  let line = binary_search a offset 0 (Array.length a) in
  let line = if a.(line) < offset then line + 1 else line in
  let col = if line = 0 then offset else offset - a.(line - 1) in
  line + 1, col + 1 (* reset 0-based offset to 1 *) + 1 (* output 1-based info *)

let update_range f range =
  let open Range in
  let open Location in
  let update_location loc =
    let line, column = f loc.offset in
    { loc with line; column }
  in
  let match_start = update_location range.match_start in
  let match_end = update_location range.match_end in
  { match_start; match_end }

let update_environment env f =
  List.fold (Environment.vars env) ~init:env ~f:(fun env var ->
      let open Option in
      let updated =
        Environment.lookup_range env var
        >>| update_range f
        >>| Environment.update_range env var
      in
      Option.value_exn updated)

let update_match f m =
  let range = update_range f m.range in
  let environment = update_environment m.environment f in
  { m with range; environment }

let update_line_col source matches =
  let line_lookup = line_map source in
  let f offset = compute_line_col_fast line_lookup offset in
  List.map matches ~f:(update_match f)

let infer_equality_constraints environment =
  let vars = Environment.vars environment in
  List.fold vars ~init:[] ~f:(fun acc var ->
      if String.is_suffix var ~suffix:"_equal" then
        match String.split var ~on:'_' with
        | _uuid :: target :: _equal ->
          let expression = Language.Ast.Equal (Variable var, Variable target) in
          expression::acc
        | _ -> acc
      else
        acc)

let apply_rule ?(substitute_in_place = true) matcher rule matches =
  let open Option in
  List.filter_map matches ~f:(fun ({ environment; _ } as matched) ->
      let rule = rule @ infer_equality_constraints environment in
      let apply = Rule.Omega.apply in
      let sat, env = apply ~substitute_in_place ~matcher rule environment in
      (if sat then env else None)
      >>| fun environment -> { matched with environment })

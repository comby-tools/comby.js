open Angstrom
open Base

open Match

let debug =
  false

let uuid_for_id_counter = ref 0
let uuid_for_sub_counter = ref 0

(** Parse the first :[id(label)] label encountered in the template. *)
let parse_first_label template =
  let label = take_while (function | '0' .. '9' | 'a' .. 'z' | 'A' .. 'Z' | '_' -> true | _ -> false) in
  let parser =
    many @@
    choice
      [ (string ":[id(" *> label <* string ")]" >>= fun label -> return (Some label))
      ; any_char >>= fun _ -> return None
      ]
  in
  parse_string ~consume:All parser template
  |> function
  | Ok label -> List.find_map label ~f:(fun x -> x)
  | Error _ -> None

let substitute_fresh template =
  let label_table = Hashtbl.create (module String) in
  let template_ref = ref template in
  let current_label_ref = ref (parse_first_label !template_ref) in
  while Option.is_some !current_label_ref do
    let label = Option.value_exn !current_label_ref in
    let id =
      match Hashtbl.find label_table label with
      | Some id -> id
      | None ->
        uuid_for_id_counter := !uuid_for_id_counter + 1;
        let id = Format.sprintf "%012d" !uuid_for_id_counter in
        Hashtbl.add_exn label_table ~key:label ~data:id;
        id
    in
    let pattern = ":[id(" ^ label ^ ")]" in
    template_ref := String.substr_replace_first !template_ref ~pattern ~with_:id;
    current_label_ref := parse_first_label !template_ref;
  done;
  !template_ref

let substitute template env =
  let substitution_formats =
    [ ":[ ", "]"
    ; ":[", ".]"
    ; ":[", "\\n]"
    ; ":[[", "]]"
    ; ":[", "]"
    (* optional syntax *)
    ; ":[? ", "]"
    ; ":[ ?", "]"
    ; ":[?", ".]"
    ; ":[?", "\\n]"
    ; ":[[?", "]]"
    ; ":[?", "]"
    ]
  in
  let template = substitute_fresh template in
  Environment.vars env
  |> List.fold ~init:(template, []) ~f:(fun (acc, vars) variable ->
      match Environment.lookup env variable with
      | Some value ->
        List.find_map substitution_formats ~f:(fun (left,right) ->
            let pattern = left^variable^right in
            if Option.is_some (String.substr_index template ~pattern) then
              Some (String.substr_replace_all acc ~pattern ~with_:value, variable::vars)
            else
              None)
        |> Option.value ~default:(acc,vars)
      | None -> acc, vars)

let of_match_context
    { range =
        { match_start = { offset = start_index; _ }
        ; match_end = { offset = end_index; _ } }
    ; _
    }
    ~source =
  if debug then Format.printf "Start idx: %d@.End idx: %d@." start_index end_index;
  let before_part =
    if start_index = 0 then
      ""
    else
      Core_kernel.String.slice source 0 start_index
  in
  let after_part = Core_kernel.String.slice source end_index (String.length source) in
  uuid_for_sub_counter := !uuid_for_sub_counter + 1;
  let hole_id = Format.sprintf "sub_%012d" !uuid_for_sub_counter in
  let rewrite_template = String.concat [before_part; ":["; hole_id;  "]"; after_part] in
  hole_id, rewrite_template

(* return the offset for holes (specified by variables) in a given match template *)
let get_offsets_for_holes rewrite_template variables =
  let sorted_variables =
    List.fold variables ~init:[] ~f:(fun acc variable ->
        match String.substr_index rewrite_template ~pattern:(":["^variable^"]") with
        | Some index ->
          (variable, index)::acc
        | None -> acc)
    |> List.sort ~compare:(fun (_, i1) (_, i2) -> i1 - i2)
    |> List.map ~f:fst
  in
  List.fold sorted_variables ~init:(rewrite_template, []) ~f:(fun (rewrite_template, acc) variable ->
      match String.substr_index rewrite_template ~pattern:(":["^variable^"]") with
      | Some index ->
        let rewrite_template =
          String.substr_replace_all rewrite_template ~pattern:(":["^variable^"]") ~with_:"" in
        rewrite_template, (variable, index)::acc
      | None -> rewrite_template, acc)
  |> snd

(* pretend we substituted vars in offsets with environment. return what the offsets are after *)
let get_offsets_after_substitution offsets environment =
  List.fold_right offsets ~init:([],0) ~f:(fun (var, offset) (acc, shift)  ->
      match Environment.lookup environment var with
      | None -> failwith "Expected var"
      | Some s ->
        let offset' = offset + shift in
        let shift = shift + String.length s in
        ((var, offset')::acc), shift)
  |> fst

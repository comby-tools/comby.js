open Js_of_ocaml

module Match = Match
module Matchers = Matchers
module Rewrite = Matchers.Rewriter

let select_matcher extension : (module Matchers.Matcher.S) =
  match Matchers.select_with_extension extension with
  | None -> (module Matchers.Generic)
  | Some matcher -> matcher

let parse_rule rule =
  let rule = String.trim rule in
  if String.equal rule "" then
    Ok None
  else
    match Matchers.Rule.create rule with
    | Ok rule -> Ok (Some rule)
    | Error error -> Error (Core_kernel.Error.to_string_hum error)

let json_error message = `Assoc [ "error", `String message ] |> Yojson.Safe.to_string

let matches_to_json matches =
  let buffer = Buffer.create 1024 in
  Buffer.add_char buffer '[';
  let first = ref true in
  List.iter
    (fun match_ ->
      if !first then
        first := false
      else
        Buffer.add_char buffer ',';
      Match.to_yojson match_ |> Yojson.Safe.to_string |> Buffer.add_string buffer)
    matches;
  Buffer.add_char buffer ']';
  Buffer.contents buffer

let convert_offsets ~source matches =
  let rec loop acc = function
    | [] -> List.rev acc
    | match_ :: rest -> loop (Match.convert_offset ~fast:true ~source match_ :: acc) rest
  in
  loop [] matches

let match_ source match_template language rule =
  let source = Js.to_string source in
  let template = Js.to_string match_template in
  let language = Js.to_string language in
  let rule = Js.to_string rule in
  match parse_rule rule with
  | Error message -> Js.string (json_error message)
  | Ok rule ->
    let (module Matcher) = select_matcher language in
    let matches = Matcher.all ?rule ~source ~template () in
    let matches = convert_offsets ~source matches in
    let json = matches_to_json matches in
    Js.string json

let rewrite source match_template rewrite_template language rule =
  let source = Js.to_string source in
  let match_template = Js.to_string match_template in
  let rewrite_template = Js.to_string rewrite_template in
  let language = Js.to_string language in
  let rule = Js.to_string rule in
  match parse_rule rule with
  | Error message -> Js.string (json_error message)
  | Ok rule ->
    let (module Matcher) = select_matcher language in
    let matches = Matcher.all ?rule ~source ~template:match_template () in
    let result = Rewrite.all ~source ~rewrite_template matches in
    let rewritten_source =
      match result with
      | None -> source
      | Some { Replacement.rewritten_source; _ } -> rewritten_source
    in
    Js.string rewritten_source

let rewrite_json source match_template rewrite_template language rule =
  let source = Js.to_string source in
  let rewritten_source = rewrite (Js.string source) match_template rewrite_template language rule in
  let json =
    `Assoc [ "rewritten_source", `String (Js.to_string rewritten_source) ] |> Yojson.Safe.to_string
  in
  Js.string json

let substitute template environment =
  let template = Js.to_string template in
  let environment = Js.to_string environment in
  match Yojson.Safe.from_string environment with
  | json ->
    (match Match.Environment.of_yojson json with
     | Ok environment -> Js.string (Rewrite.substitute template environment)
     | Error message -> Js.string message)
  | exception Yojson.Json_error message -> Js.string ("could not parse: " ^ message)

let () =
  Js.export "match" match_;
  Js.export "rewrite" rewrite;
  Js.export "rewriteJson" rewrite_json;
  Js.export "substitute" substitute

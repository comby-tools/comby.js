open Js_of_ocaml

open Comby_js

let select_matcher extension : (module Matchers.Matcher) =
  match Matchers.Omega.select_with_extension extension with
  | None -> (module Matchers.Omega.Generic)
  | Some m -> m

let match_ :
  Js.js_string Js.t ->
  Js.js_string Js.t ->
  Js.js_string Js.t ->
  Js.js_string Js.t ->
  Js.js_string Js.t =
  fun source match_template language rule ->
  let source = Js.to_string source in
  let template = Js.to_string match_template in
  let language = Js.to_string language in
  let rule = Js.to_string rule in
  let (module M) = select_matcher language in
  let matches = M.all ?configuration:None ~rule ~source ~template in
  let matches = Pipeline.update_line_col source matches in
  let result = Yojson.Safe.to_string (`List (List.map Match.to_yojson matches)) in
  Js.string result

let rewrite :
  Js.js_string Js.t ->
  Js.js_string Js.t ->
  Js.js_string Js.t ->
  Js.js_string Js.t ->
  Js.js_string Js.t ->
  Js.js_string Js.t =
  fun source match_template rewrite_template language rule ->
  let source = Js.to_string source in
  let match_template = Js.to_string match_template in
  let rewrite_template = Js.to_string rewrite_template in
  let rule = Js.to_string rule in
  let language = Js.to_string language in
  let (module M) = select_matcher language in
  M.set_rewrite_template rewrite_template;
  let _ = M.all ?configuration:None ~rule ~source ~template:match_template in
  let result = M.get_rewrite_result () in
  Js.string result

let substitute :
  Js.js_string Js.t ->
  Js.js_string Js.t ->
  Js.js_string Js.t =
  fun template environment ->
  let template = Js.to_string template in
  let environment = Js.to_string environment in
  match Yojson.Safe.from_string environment with
  | json ->
    begin
      Match.Environment.of_yojson json
      |> function
      | Ok environment ->
        Rewriter.Rewrite_template.substitute template environment
        |> fst
        |> Js.string
      | Error err ->
        Js.string err
    end
  | exception Yojson.Json_error err ->
    Js.string @@ "could not parse: " ^ err

let () =
  Js.export "match" match_;
  Js.export "rewrite" rewrite;
  Js.export "substitute" substitute

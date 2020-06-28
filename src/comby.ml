open Js_of_ocaml

open Comby_js

let match_ : Js.js_string Js.t -> Js.js_string Js.t -> Js.js_string Js.t -> Js.js_string Js.t =
  fun source match_template rule ->
  let module M = Matchers.Omega.Go in
  let source = Js.to_string source in
  let match_template = Js.to_string match_template in
  let matches = M.all ?configuration:None ~rule:(Js.to_string rule) ~source ~template:match_template in
  let matches = Pipeline.update_line_col source matches in
  let result = Yojson.Safe.to_string (`List (List.map Match.to_yojson matches)) in
  Js.string result

let rewrite : Js.js_string Js.t -> Js.js_string Js.t -> Js.js_string Js.t -> Js.js_string Js.t -> Js.js_string Js.t =
  fun source match_template rewrite_template rule ->
  let module M = Matchers.Omega.Go in
  let source = Js.to_string source in
  let match_template = Js.to_string match_template in
  let rewrite_template = Js.to_string rewrite_template in
  M.set_rewrite_template rewrite_template;
  let _ = M.all ?configuration:None ~rule:(Js.to_string rule) ~source ~template:match_template in
  let result = M.get_rewrite_result () in
  Js.string result

let () =
  Js.export "match" match_;
  Js.export "rewrite" rewrite

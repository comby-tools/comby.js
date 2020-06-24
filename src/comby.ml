open Js_of_ocaml

open Comby_js

let match_ : Js.js_string Js.t -> Js.js_string Js.t -> Js.js_string Js.t =
  fun source match_template ->
  let source = Js.to_string source in
  let match_template = Js.to_string match_template in
  let matches = Matchers.Omega.C.all ?configuration:None ~source ~template:match_template in
  let result = Yojson.Safe.to_string (`List (List.map Match.to_yojson matches)) in
  Js.string result

let rewrite : Js.js_string Js.t -> Js.js_string Js.t -> Js.js_string Js.t -> Js.js_string Js.t =
  fun source match_template rewrite_template ->
  let source = Js.to_string source in
  let match_template = Js.to_string match_template in
  let rewrite_template = Js.to_string rewrite_template in
  let matches = Matchers.Omega.C.all ?configuration:None ~source ~template:match_template in
  let rewrite = Rewriter.Rewrite.all ~source ~rewrite_template matches in
  let result =
    match rewrite with
    | Some { rewritten_source; _ } -> rewritten_source
    | None -> ""
  in
  Js.string result


let () =
  Js.export "match" match_;
  Js.export "rewrite" rewrite

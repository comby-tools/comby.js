open Vangstrom

let debug = Stdlib.Sys.getenv_opt "DEBUG_COMBY" |> Option.is_some

module type Regexp_engine_intf = sig
  type t
  type substrings

  val make : string -> t
  val get_substring : substrings -> int -> string option
  val get_all_substrings : substrings -> string array
  val exec : rex:t -> pos:int -> Bytes.t -> substrings option
end

type t =
  { buffer_pos : int
  ; buffer : bytes
  }

(* I think I should just implement the analog of string_ for regex with some bounded buffer size. *)

module Make (Regexp : Regexp_engine_intf) = struct
  let match_regexp s pos rex = Regexp.exec ~rex ~pos:(pos - s.buffer_pos) s.buffer
  let make_regexp pat = Regexp.make pat

  (* TODO: tests and blit thing below *)

  (* FIXME: size. about advance => want to use internal unsafe_apply_opt
     actually. cf. string_ in angstrom.ml. instead, trying "do peek, then
     advance/commit." *)
  let regexp rex =
    (* Why do Unsafe if I can just do peek_string? => So I don't allocate on copy of buffer. *)
    (* But it looks like we can't avoid allocation in converting bigstringaf to bytes *)
    Unsafe.peek 1 (fun buffer ~off ~len:_ -> Bigstringaf.length buffer - off)
    >>= fun n ->
    Unsafe.peek n (fun buffer ~off ~len ->
      (* This still does a copy :( *)
      let bytes = Bytes.create len in
      Bigstringaf.unsafe_blit_to_bytes buffer ~src_off:off bytes ~dst_off:0 ~len;
      if debug then Format.printf "Matching regex against string: %S@." @@ Bytes.to_string bytes;
      match Regexp.exec ~rex ~pos:0 bytes with
      | None ->
        if debug then Format.printf "None (1)@.";
        None
      | Some substrings ->
        (match Regexp.get_substring substrings 0 with
         | None ->
           if debug then Format.printf "None (2)@.";
           None
         | Some result ->
           if debug then Format.printf "Matchy Matchy (3)@.";
           Some (result, String.length result)))
    >>= function
    | Some (result, n) ->
      (* if empty string matches, this hole like for optionals (x?), advance 1. *)
      (* we want to advance one so parsing can continue, but if we advance 1 here we will think
         that the match context is at least length 1 and not 0 if this hole is the only thing
         defining the match context *)
      (* let n = if n > 0 then n else 1 in
         advance n >>= fun () -> *)
      if debug then Format.printf "Result indeed: %S len %d@." result n;
      advance n >>= fun () -> return result
    | None -> fail "No match"
end

module RE = struct
  module Engine : Regexp_engine_intf = struct
    type t = Re.re
    type substrings = Re.substrings

    let compile_flags = [ `Anchored ]
    let make pattern = Re.Perl.(compile (re ~opts:compile_flags pattern))

    let get_substring s idx =
      match Re.get s idx with
      | result -> Some result
      | exception Not_found -> None

    let get_all_substrings s = Re.get_all s

    let exec ~rex ~pos b =
      match Re.exec ~pos rex (Bytes.unsafe_to_string b) with
      | result -> Some result
      | exception Not_found -> None
  end

  include Make (Engine)
end

module JS = struct
  module Js = Js_of_ocaml.Js

  module Engine : Regexp_engine_intf = struct
    type t = Js.regExp Js.t
    type substrings = Js.match_result Js.t

    let make pattern =
      new%js Js.regExp_withFlags (Js.bytestring ("^(?:" ^ pattern ^ ")")) (Js.string "")

    let get_substring s idx =
      Js.Optdef.to_option (Js.Optdef.map (Js.array_get s idx) Js.to_bytestring)

    let get_all_substrings s =
      match get_substring s 0 with
      | Some matched -> [| matched |]
      | None -> [||]

    let exec ~rex ~pos b =
      let s = Bytes.unsafe_to_string b in
      let len = String.length s - pos in
      let s = if pos = 0 then s else String.sub s pos len in
      Js.Opt.to_option (Js.Opt.map (rex##exec (Js.bytestring s)) Js.match_result)
  end

  include Make (Engine)
end

type backend =
  | JavaScript
  | Re

let backend =
  ref
    (match Sys.backend_type with
     | Other _ -> JavaScript
     | Native | Bytecode -> Re)

let set_backend = function
  | JavaScript -> backend := JavaScript
  | Re -> backend := Re

let backend_to_string = function
  | JavaScript -> "js"
  | Re -> "re"

let get_backend () = !backend
let get_backend_name () = backend_to_string !backend

module Active = struct
  module Engine : Regexp_engine_intf = struct
    type t =
      | JavaScript of JS.Engine.t
      | Re of RE.Engine.t

    type substrings =
      | JavaScript_substrings of JS.Engine.substrings
      | Re_substrings of RE.Engine.substrings

    let make pattern =
      match !backend with
      | JavaScript -> JavaScript (JS.Engine.make pattern)
      | Re -> Re (RE.Engine.make pattern)

    let get_substring substrings idx =
      match substrings with
      | JavaScript_substrings substrings -> JS.Engine.get_substring substrings idx
      | Re_substrings substrings -> RE.Engine.get_substring substrings idx

    let get_all_substrings = function
      | JavaScript_substrings substrings -> JS.Engine.get_all_substrings substrings
      | Re_substrings substrings -> RE.Engine.get_all_substrings substrings

    let exec ~rex ~pos b =
      match rex with
      | JavaScript rex ->
        Option.map
          (fun substrings -> JavaScript_substrings substrings)
          (JS.Engine.exec ~rex ~pos b)
      | Re rex -> Option.map (fun substrings -> Re_substrings substrings) (RE.Engine.exec ~rex ~pos b)
  end

  include Make (Engine)
end

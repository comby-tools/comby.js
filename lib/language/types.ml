open Base

open Matchers
open Match

open Ast

type t = Ast.t

type result = bool * environment option

module type Engine = sig
  val sat : result -> bool

  val result_env : result -> environment option

  val create : string -> expression list Or_error.t

  val apply
    :  ?matcher:(module Matcher)
    -> ?substitute_in_place:bool
    -> t
    -> environment
    -> result
end

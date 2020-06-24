type atom =
  | Variable of string
  | String of string

type antecedent = atom

type expression =
  | True
  | False
  | Equal of atom * atom
  | Not_equal of atom * atom
  | Match of atom * (antecedent * consequent) list
  | RewriteTemplate of string
  | Rewrite of atom * (antecedent * expression)
and consequent = expression list

let (=) left right = Equal (left, right)

let (<>) left right = Not_equal (left, right)

type t = expression list

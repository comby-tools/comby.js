module Configuration = Configuration
module Syntax = Types.Syntax
module type Matcher = Types.Matcher.S

module type Engine = Types.Match_engine.S

module Omega : Engine

type t =
  { offset : int
  ; line : int
  ; column : int
  }
[@@deriving yojson, eq]

let default =
  { offset = -1
  ; line = -1
  ; column = -1
  }

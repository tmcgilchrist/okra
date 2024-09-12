module Unit = struct
  module Day = struct
    type t = float

    let keywords = [ "d"; "day"; "days" ]

    let of_string x y =
      if List.mem y keywords && (Float.is_integer @@ Float.div x 0.125) then
        Some x
      else None
  end

  module Hour = struct
    type t = float

    let keywords = [ "h"; "hour"; "hours" ]

    let of_string x y =
      if List.mem y keywords && Float.is_integer x then Some x else None
  end

  let keywords = Day.keywords @ Hour.keywords
end

type t = Days of Unit.Day.t | Hours of Unit.Hour.t

let days x = Days x
let hours x = Hours x
let ( ||| ) x y = match x with Some _ -> x | None -> y

let of_string x y =
  Option.map days @@ Unit.Day.of_string x y
  ||| Option.map hours @@ Unit.Hour.of_string x y

let to_days = function Days x -> x | Hours x -> x *. 0.125
let equal x y = Float.equal (to_days x) (to_days y)
let nil = Days 0.

let add x y =
  match (x, y) with
  | Hours x, Hours y -> Hours (x +. y)
  | x, y -> Days (to_days x +. to_days y)

let ( + ) = add

let pp fs x =
  let data, unit =
    match x with Days x -> (x, "day") | Hours x -> (x, "hour")
  in
  if Float.equal data 1. then Fmt.pf fs "1 %s" unit
  else Fmt.pf fs "%g %ss" data unit

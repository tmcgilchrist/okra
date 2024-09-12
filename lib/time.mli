module Unit : sig
  val keywords : string list
end

type t

val of_string : float -> string -> t option
val nil : t
val days : float -> t
val equal : t -> t -> bool
val add : t -> t -> t

val ( + ) : t -> t -> t
(** Alias for [add]. *)

val pp : t Fmt.t

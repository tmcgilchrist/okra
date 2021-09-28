(*
 * Copyright (c) 2021 Patrick Ferris <pf341@patricoferris.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

type t
(** A specific week, month and year *)

val week : t -> int
(** [week t] gets the week from [t] *)

val month : t -> int
(** [week t] gets the week from [t] *)

val year : t -> int
(** [year t] gets the year from [t] *)

val make_week : week:int -> year:int -> t
(** [make_week ~week ~year] constructs a new [t] *)

val make_month : month:int -> year:int -> t
val make : week:int -> month:int -> year:int -> t

val this_week : unit -> t
(** [this_week ()] gets the current week and year *)

val this_month : unit -> t
(** [this_month ()] gets the current month as a integer *)

val range_of_week : t -> CalendarLib.Date.t * CalendarLib.Date.t
(** [range_of_week t] returns the start and end dates of the week *)

val range_of_month : t -> CalendarLib.Date.t * CalendarLib.Date.t
(** [range_of_month t] returns the first and last dates of the month *)

val github_week : t -> string * string
(** [github_week t] converts [t] into floats as strings ready to be passed to
    the Github API *)

val github_month : t -> string * string
(** [github_month m y] converts the month [m] and year [y] into floats as
    strings ready to be passed to the Github API *)

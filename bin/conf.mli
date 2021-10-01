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
(** The type for okra configurations *)

val default : t
(** A default configuration *)

val projects : t -> Okra.Activity.project list
(** A user's list of activer projects *)

val locations : t -> string list
(** A list of locations to use when aggregating reports *)

val footer : t -> string option
(** An optional footer to append to the end of your engineer reports *)

val okr_db : t -> string option
(** [okr_db] is the location of the OKR database. *)

val load : string -> (t, [ `Msg of string ]) result
(** [load file] attempts to load a configuration from [file] *)

val cmdliner : string Cmdliner.Term.t
(** Cmdliner term for configuration file location *)

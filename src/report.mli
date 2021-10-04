(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
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
type project
type objective

module Project : sig
  type report := t
  type t = project

  val name : t -> string
  val objectives : t -> objective list
  val krs : t -> KR.t list
  val find : report -> string -> t option
end

module Objective : sig
  type report := t
  type t = objective

  val name : t -> string
  val krs : t -> KR.t list
  val find : project -> string -> t option
  val find_all : report -> string -> (project * t) list
end

val dump : t Fmt.t
val of_krs : ?okr_db:Masterdb.t -> KR.t list -> t
val of_projects : project list -> t
val of_objectives : project:string -> objective list -> t

val of_markdown :
  ?ignore_sections:string list ->
  ?include_sections:string list ->
  ?okr_db:Masterdb.t ->
  Parser.markdown ->
  t

val iter :
  ?project:(string -> project -> unit) ->
  ?objective:(string -> objective -> unit) ->
  (KR.t -> unit) ->
  t ->
  unit

val find : t -> ?title:string -> ?id:string -> unit -> KR.t list
val add : ?okr_db:Masterdb.t -> t -> KR.t -> unit
val all_krs : t -> KR.t list
val new_krs : t -> KR.t list

val pp :
  ?show_time:bool -> ?show_time_calc:bool -> ?show_engineers:bool -> t Printer.t
(** [pp] pretty-print weekly team reports.

    When [show_time_calc] is set, an extra line will be added to the output each
    time the same entry is included in the report with a sum at the end. This is
    useful for showing the intermediate steps when aggreating multiple reports
    that contain the same KR.

    [show_time] shows the time entries [show_engineers] shows the list of
    engineers *)

val print :
  ?show_time:bool -> ?show_time_calc:bool -> ?show_engineers:bool -> t -> unit

(** {2 Filtering} *)

module Filter : sig
  type t

  val empty : t

  type kr = [ `New_KR | `ID of string ]

  val kr_of_string : string -> kr
  (** [kr_of_string s] is [`New_KR] iff [s="New KR"], and [`ID s] otherwise. *)

  val string_of_kr : kr -> string

  val v :
    ?include_projects:string list ->
    ?exclude_projects:string list ->
    ?include_objectives:string list ->
    ?exclude_objectives:string list ->
    ?include_krs:kr list ->
    ?exclude_krs:kr list ->
    ?include_engineers:string list ->
    ?exclude_engineers:string list ->
    unit ->
    t
  (** Build a filter.

      Keep the KR [k] in the report iff the conjonction of the following is
      true:

      - [include_project] is not empty AND [k.project] is in [include_projects]
        OR [exclude_project] is not empty AND [k.project] is not in
        [exclude_project];
      - [include_objective] is not empty AND [k.objective] is in
        [include_objectives] OR [exclude_objectives] is not empty AND
        [k.objective] is not in [exclude_projects];
      - [include_krs] is not empty AND [k.krs] is [Some id] AND [id] is in
        [include_krs] OR [exclude_krs] is not empty AND [k.krs] is [Some id] AND
        [id] is not in [exclude_projects];
      - [include_engineers] is not empty AND the intersection of
        [k.time_per_engineer] and [include_engineers] is not empty OR
        [exclude_krs] is not empty AND [k.time_per_engineer] and
        [exclude_engineers] is empty. *)
end

type filter = Filter.t

val filter : filter -> t -> t

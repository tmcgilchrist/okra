(*
 * Copyright (c) 2021 Patrick Ferris <pf341@patricoferris.com>
 * Copyright (c) 2021 Tim McGilchrist <timmcgil@gmail.com>
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
(** The type for your weekly activity *)

type project = { title : string; items : string list }

val make : projects:project list -> Get_activity.Contributions.t -> t
(** [make_activity ~projects activites] builds a new weekly activity *)

val pp_ga_item : no_links:bool -> Get_activity.Contributions.item Fmt.t
(** [pp_ga_item ppf item] prints the get-activity item *)

val pp : ?no_links:bool -> t Fmt.t
(** [pp ppf activity] formats a weekly activity into a template that needs some
    editing to get it into the correct format.

    [no_links] controls rendering of markdown links to issues, reviews and prs.
    Defaults to [false] and longer url links. [true] for GitHub style shorter
    links eg project/repo#number *)

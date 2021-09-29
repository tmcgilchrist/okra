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

open Okra
open Cmdliner
module Cal = CalendarLib.Calendar

(* Calendar term *)

let week_term =
  Arg.value
  @@ Arg.opt Arg.(some int) None
  @@ Arg.info ~doc:"The week of the year defaulting to the current week"
       ~docv:"WEEK" [ "w"; "week" ]

let year_term =
  Arg.value
  @@ Arg.opt Arg.(some int) None
  @@ Arg.info ~doc:"The year defaulting to the current year" ~docv:"YEAR"
       [ "y"; "year" ]

let calendar_term : Calendar.t Term.t =
  let open Let_syntax_cmdliner in
  let+ week = week_term and+ year = year_term in
  let week = Option.value ~default:(Cal.week (Cal.now ())) week in
  let year = Option.value ~default:(Cal.year (Cal.now ())) year in
  Calendar.make ~week ~year

let no_activity =
  Arg.value
  @@ Arg.flag
  @@ Arg.info
       ~doc:
         "The --no-activity flag will disable any attempt to generate activity \
          reports from Github"
       ~docv:"NO-ACTIVITY" [ "no-activity" ]

(* Get activity configuration *)
let home =
  match Sys.getenv_opt "HOME" with
  | None -> Fmt.failwith "$HOME is not set!"
  | Some dir -> dir

let default_token_file =
  let ( / ) = Filename.concat in
  home / ".github" / "github-activity-token"

let token =
  Arg.value
  @@ Arg.opt Arg.file default_token_file
  @@ Arg.info
       ~doc:
         "The path to a file containing your github token, defaults to \
          ~/.github/github-activity-token"
       ~docv:"TOKEN" [ "t"; "token" ]

let get_or_error = function
  | Ok v -> v
  | Error (`Msg m) ->
      Fmt.epr "%s" m;
      exit 1

module Fetch = Get_activity.Contributions.Fetch (Cohttp_lwt_unix.Client)

let run cal projects token no_activity =
  let period = Calendar.github_week cal in
  let week = Calendar.week cal in
  let activity =
    if no_activity then
      Get_activity.Contributions.
        { username = "<USERNAME>"; activity = Repo_map.empty }
    else
      Lwt_main.run (Fetch.exec ~period ~token)
      |> Get_activity.Contributions.of_json ~from:(fst period)
  in
  let from, to_ = Calendar.range_of_week cal in
  let format_date f = CalendarLib.Printer.Date.fprint "%0Y/%0m/%0d" f in
  let header =
    Fmt.str "%s week %i: %a -- %a" activity.username week format_date from
      format_date to_
  in
  let activity = Activity.make ~projects activity in
  Fmt.pr "%s\n\n%a" header Activity.pp activity

let term =
  let open Let_syntax_cmdliner in
  let+ cal = calendar_term
  and+ okra_file = Conf.cmdliner
  and+ token_file = token
  and+ no_activity = no_activity
  and+ () = Common.setup () in
  let token =
    (* If [no_activity] is specfied then the token will not be used, don't try
       to load the file in that case *)
    if no_activity then ""
    else get_or_error @@ Get_activity.Token.load token_file
  in
  let okra_conf =
    match get_or_error @@ Bos.OS.File.exists (Fpath.v okra_file) with
    | false -> Conf.default
    | true -> get_or_error @@ Conf.load okra_file
  in
  run cal (Conf.projects okra_conf) token no_activity

let cmd =
  let info =
    Term.info "generate"
      ~doc:"Generate an initial weekly report based on Github activity"
      ~man:
        [
          `S Manpage.s_description;
          `P
            "Produces a markdown document using your activity on Github. See \
             the options below for changing things like which week to query \
             for and where to find your token. To generate a token see the \
             README at https://github.com/talex5/get-activity.";
        ]
  in
  (term, info)

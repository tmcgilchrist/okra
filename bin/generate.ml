(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
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

open Okra
open Cmdliner
module Cal = CalendarLib.Calendar

(* Calendar term *)

let week_term =
  Arg.value
  @@ Arg.opt Arg.(some int) None
  @@ Arg.info ~doc:"The week of the year defaulting to the current week"
       ~docv:"WEEK" [ "week" ]

let weeks_term =
  Arg.value
  @@ Arg.opt Arg.(some (pair ~sep:'-' int int)) None
  @@ Arg.info ~doc:"A range specified by a start and end week (inclusive)"
       ~docv:"WEEK" [ "weeks" ]

let month_term =
  Arg.value
  @@ Arg.opt Arg.(some int) None
  @@ Arg.info
       ~doc:
         "The month of the year defaulting to the current month (January = 1)"
       ~docv:"MONTH" [ "m"; "month" ]

let year_term =
  Arg.value
  @@ Arg.opt Arg.(some int) None
  @@ Arg.info ~doc:"The year defaulting to the current year" ~docv:"YEAR"
       [ "y"; "year" ]

let no_links_term =
  Arg.value
  @@ Arg.flag
  @@ Arg.info ~doc:"Generate shortened GitHub style urls" ~docv:"NO_LINKS"
       [ "no-links" ]

let calendar_term : Calendar.t Term.t =
  let open Let_syntax_cmdliner in
  let+ week = week_term
  and+ weeks = weeks_term
  and+ month = month_term
  and+ year = year_term in
  match (week, weeks, month, year) with
  | None, None, None, year -> Calendar.of_week ?year (Cal.now () |> Cal.week)
  | Some week, _, _, year -> Calendar.of_week ?year week
  | None, Some range, _, year -> Calendar.of_week_range ?year range
  | None, None, Some month, year -> Calendar.of_month ?year month

(* The kind of report we are generating
     - engineer: a report for an individual engineer
     - reposiories: 1 or more repository contributions *)

type kind = Engineer | Repositories of string list

let repositories =
  Arg.value
  @@ Arg.opt Arg.(list string) []
  @@ Arg.info ~doc:"A list of repositories to generate reports for"
       ~docv:"REPOSITORIES" [ "repositories" ]

let kind_term : kind Term.t =
  let open Let_syntax_cmdliner in
  let+ repositories = repositories in
  if repositories = [] then Engineer else Repositories repositories

let no_activity =
  Arg.value
  @@ Arg.flag
  @@ Arg.info
       ~doc:
         "The --no-activity flag will disable any attempt to generate activity \
          reports from Github"
       ~docv:"NO-ACTIVITY" [ "no-activity" ]

let with_repositories_term =
  Arg.value
  @@ Arg.opt Arg.(list string) []
  @@ Arg.info
       ~doc:
         "Specify a list of Github repositories (e.g. ocaml/opam-repository) \
          to get your merges from. This is probably only useful for people who \
          spend time merging PRs but not explicitly reviewing them so the \
          activity won't appear normally (or creating the PR)"
       [ "with-repositories" ]

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

module Fetch = Get_activity.Contributions.Fetch (Cohttp_lwt_unix.Client)
module Repo_fetch = Okra.Repo_report.Make (Cohttp_lwt_unix.Client)

let run_engineer conf cal projects token no_activity no_links with_repositories
    =
  let open Lwt.Syntax in
  let period = Calendar.to_iso8601 cal in
  let week = Calendar.week cal in
  let activity, merges =
    if no_activity then
      ( Get_activity.Contributions.
          { username = "<USERNAME>"; activity = Repo_map.empty },
        [] )
    else
      let contributions () =
        let+ fetch = Fetch.exec ~period ~token
        and+ report =
          (* When a user specifies `with_repositories` we also fetch reports
             from these repositories and filter the PRs made over the same
             time period that were merged by the user returned by fetching
             the original get-activity. *)
          if with_repositories = [] then
            Lwt.return Repo_report.Project_map.empty
          else Repo_fetch.get ~period ~token with_repositories
        in
        let contribs =
          Get_activity.Contributions.of_json ~from:(fst period) fetch
        in
        let merges =
          let bindings = Repo_report.Project_map.bindings report in
          List.map
            (fun (_, v) ->
              List.filter
                (fun pr -> Some contribs.username = pr.Repo_report.PR.merged_by)
                v.Repo_report.prs)
            bindings
        in
        (contribs, List.concat merges)
      in
      Lwt_main.run (contributions ())
  in
  let from, to_ = Calendar.range cal in
  let format_date f = CalendarLib.Printer.Date.fprint "%0Y/%0m/%0d" f in
  let pp_pr ppf pr =
    let item =
      Get_activity.Contributions.
        {
          kind = `PR;
          repo = "";
          date = pr.Repo_report.PR.created_at;
          url = pr.url;
          title = pr.title;
          body = pr.body;
        }
    in
    Fmt.pf ppf "  - Merged %a" (Activity.pp_ga_item ~no_links) item
  in
  let header =
    Fmt.str "%s week %i: %a -- %a" activity.username week format_date from
      format_date to_
  in
  let pp_footer ppf conf = Fmt.(pf ppf "\n\n%a" string conf) in
  let activity = Activity.make ~projects activity in
  Fmt.(
    pr "%s\n\n%a%a%a" header (Activity.pp ~no_links) activity
      Fmt.(list pp_pr)
      merges (option pp_footer) (Conf.footer conf))

let get_or_error = function
  | Ok v -> v
  | Error (`Msg m) ->
      Fmt.epr "%s" m;
      exit 1

let run_monthly cal repos token =
  let from, to_ = Calendar.range cal in
  let format_date f = CalendarLib.Printer.Date.fprint "%0Y/%0m/%0d" f in
  let period = Calendar.to_iso8601 cal in
  let projects = Lwt_main.run (Repo_fetch.get ~period ~token repos) in
  Fmt.(
    pf stdout "# Reports (%a - %a)\n\n%a" format_date from format_date to_
      Repo_report.pp projects)

let run cal okra_conf token no_activity no_links with_repositories = function
  | Engineer ->
      run_engineer okra_conf cal (Conf.projects okra_conf) token no_activity
        no_links with_repositories
  | Repositories repos -> run_monthly cal repos token

let term =
  let open Let_syntax_cmdliner in
  let+ cal = calendar_term
  and+ token_file = token
  and+ no_activity = no_activity
  and+ with_repositories = with_repositories_term
  and+ kind = kind_term
  and+ no_links = no_links_term
  and+ okra_conf = Common.conf
  and+ () = Common.setup () in
  let token =
    (* If [no_activity] is specfied then the token will not be used, don't try
       to load the file in that case *)
    if no_activity then ""
    else get_or_error @@ Get_activity.Token.load token_file
  in
  run cal okra_conf token no_activity no_links with_repositories kind

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

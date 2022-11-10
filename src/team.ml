(*
 * Copyright (c) 2022 Thibaut Mattio <thibaut.mattio@gmail.com>
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

module Member = struct
  type t = { name : string; github : string }

  let make ~name ~github = { name; github }
  let name { name; _ } = name
  let github { github; _ } = github
end

type t = { name : string; members : Member.t list }

let make ~name ~members = { name; members }
let name { name; _ } = name
let members { members; _ } = members

type report = Not_found | Complete | Erroneous of Lint.lint_error
type lint_report = (t * (Member.t * (int * report) list) list) list

let lint_member_week admin_dir member week =
  let fname =
    Format.asprintf "%s/weekly/2022/%i/%s.md" admin_dir week
      (Member.github member)
  in
  match Sys.file_exists fname with
  | false -> Not_found
  | true -> (
      let ic = In_channel.open_text fname in
      match
        Lint.lint ~include_sections:[ "Last week" ] ~ignore_sections:[] ic
      with
      | Ok () -> Complete
      | Error e -> Erroneous e)

let lint_member admin_dir weeks member =
  let lint_member_week = lint_member_week admin_dir member in
  List.map (fun week -> (week, lint_member_week week)) weeks

let lint_team admin_dir weeks members =
  let lint_member = lint_member admin_dir weeks in
  List.map (fun member -> (member, lint_member member)) members

let lint admin_dir weeks teams =
  let lint_team = lint_team admin_dir weeks in
  List.map (fun team -> (team, lint_team (members team))) teams

let pp_report ppf = function
  | Not_found -> Fmt.pf ppf "Not found ❌"
  | Complete -> Fmt.pf ppf "Complete ✅"
  | Erroneous e -> Fmt.pf ppf "Lint error ⚠️@ @[<v 0>%a@]" Lint.pp_error e

let pp_lint_report ppf lint_report =
  let pp_report_lint ppf (week, report) =
    Fmt.pf ppf "@[<hv 0>+ Report week %i: @[<v 0>%a@]@]" week pp_report report
  in
  let pp_member_lint ppf (member, member_lint) =
    Fmt.pf ppf "+ %s@;<1 4>%a" (Member.name member)
      (Fmt.list ~sep:(Fmt.any "@;<1 4>") pp_report_lint)
      member_lint
  in
  let pp_team_lint ppf (team, members_list) =
    Fmt.pf ppf "=== %s === @;<1 2>%a" (name team)
      (Fmt.list ~sep:(Fmt.any "@;<1 2>") pp_member_lint)
      members_list
  in
  Fmt.pf ppf "@[<v 0>%a@]@."
    (Fmt.list ~sep:(Fmt.any "@;<1 2>") pp_team_lint)
    lint_report

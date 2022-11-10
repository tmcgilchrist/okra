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

open Cmdliner

let lint conf week_range admin_dir =
  let admin_dir = Option.get admin_dir in
  let week_range =
    match week_range with
    | Some weeks -> weeks
    | None -> failwith "Need to specify week range."
  in
  let lhe, rhe =
    match String.split_on_char '.' week_range with
    | [ lhe; rhe ] -> (lhe, rhe)
    | _ -> failwith "Couldn't decode week range."
  in
  let lhe = int_of_string lhe in
  let rhe = int_of_string rhe in
  let weeks = List.init (rhe - lhe + 1) (fun x -> lhe + x) in
  let teams = Conf.teams conf in
  let lint_report = Okra.Team.lint admin_dir weeks teams in
  Format.printf "%a" Okra.Team.pp_lint_report lint_report

(* Commands *)

let lint_cmd =
  let admin_dir =
    let doc = "Path of the admin repository directory." in
    Arg.(
      value
      & opt (some dir) (Some Filename.current_dir_name)
      & info [ "C"; "admin-dir" ] ~docv:"ADMIN_DIR" ~doc)
  in
  let weeks =
    let doc = "The week range to lint reports for." in
    Arg.(
      value & opt (some string) None & info [ "W"; "weeks" ] ~docv:"WEEKS" ~doc)
  in
  let doc = "Lint reports for a team." in
  let info = Cmd.info "lint" ~doc in
  Cmd.v info Term.(const lint $ Common.conf $ weeks $ admin_dir)

let cmd =
  let doc = "Work on multiple reports for a team" in
  let info = Cmd.info "team" ~doc in
  Cmd.group info [ lint_cmd ]

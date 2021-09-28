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

open Okra
open Cmdliner
module Cal = CalendarLib.Calendar

(* Calendar term *)

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

let repos =
  Arg.value
  @@ Arg.pos_all Arg.string []
  @@ Arg.info
       ~doc:
         "The path to a file containing your github token, defaults to \
          ~/.github/github-activity-token"
       []

let get_or_error = function
  | Ok v -> v
  | Error (`Msg m) ->
      Fmt.epr "%s" m;
      exit 1

module Fetch = Okra.Monthly.Make (Cohttp_lwt_unix.Client)

let run month year repos token =
  let month = Option.value ~default:(Calendar.this_month ()) month in
  let year =
    Option.value ~default:(Calendar.this_week () |> Calendar.year) year
  in
  let ((from, to_) as period) = Calendar.github_month month year in
  let stuff = Lwt_main.run (Fetch.get ~period ~token repos) |> List.map snd in
  Fmt.(pf stdout "# Reports (%s - %s)\n\n%a" from to_ (list Monthly.pp_data))
    stuff

let term =
  let make_with_file month year token_file repos =
    let token = get_or_error @@ Get_activity.Token.load token_file in
    run month year repos token
  in
  Term.(const make_with_file $ month_term $ year_term $ token $ repos)

let cmd =
  let info =
    Term.info "monthly"
      ~doc:
        "Generate the monthly activity for a given set of Github repositories"
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

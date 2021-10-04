(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
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

let include_sections =
  let i =
    Arg.info [ "include-sections" ]
      ~doc:
        "If non-empty, only aggregate entries under these sections - \
         everything else is ignored."
  in
  Arg.(value & opt (list string) [] i)

let ignore_sections =
  let i =
    Arg.info [ "ignore-sections" ]
      ~doc:
        "If non-empty, ignore everyhing under these sections (titles) from the \
         report"
  in
  Arg.(value & opt (list string) [ "OKR updates" ] i)

let include_projects =
  let i =
    Arg.info [ "include-projects" ]
      ~doc:"If non-empty, only include this list of projects in the output."
      ~docv:"PROJECT"
  in
  Arg.(value (opt (list string) [] i))

let exclude_projects =
  let i =
    Arg.info [ "exclude-projects" ]
      ~doc:"If non-empty, exclude projects in this list from the output."
      ~docv:"PROJECT"
  in

  Arg.(value (opt (list string) [] i))

let exclude_objectives =
  let i =
    Arg.info [ "include-objectives" ]
      ~doc:"If non-empty, only include this list of objectives in the output."
      ~docv:"OBJECTIVE"
  in
  Arg.(value (opt (list string) [] i))

let include_objectives =
  let i =
    Arg.info [ "exclude-objectives" ]
      ~doc:"If non-empty, exclude objectives in this list from the output."
      ~docv:"OBJECTIVE"
  in
  Arg.(value (opt (list string) [] i))

let include_krs =
  let i =
    Arg.info [ "include-krs" ]
      ~doc:"If non-empty, only include this list of KR IDs in the output."
      ~docv:"ID"
  in
  Arg.(value (opt (list string) [] i))

let exclude_krs =
  let i =
    Arg.info [ "exclude-krs" ]
      ~doc:"If non-empty, exclude KR IDs in this list from the output."
      ~docv:"ID"
  in
  Arg.(value (opt (list string) [] i))

let include_engineers =
  let i =
    Arg.info [ "include-engineers" ]
      ~doc:"If non-empty, only include this list of engineers in the output."
      ~docv:"NAME"
  in
  Arg.(value (opt (list string) [] i))

let exclude_engineers =
  let i =
    Arg.info [ "exclude-engineers" ]
      ~doc:"If non-empty, exclude engineers in this list from the output."
      ~docv:"NAME"
  in
  Arg.(value (opt (list string) [] i))

let files = Arg.(value & pos_all non_dir_file [] & info [] ~docv:"FILE")

let output =
  Arg.(value & opt (some string) None & info [ "o"; "output" ] ~docv:"FILE")

let in_place = Arg.(value & flag & info [ "i"; "in-place" ])

let filter =
  let f include_projects exclude_projects include_objectives exclude_objectives
      include_krs exclude_krs include_engineers exclude_engineers =
    let include_krs = List.map Okra.Report.Filter.kr_of_string include_krs in
    let exclude_krs = List.map Okra.Report.Filter.kr_of_string exclude_krs in
    Okra.Report.Filter.v ~include_projects ~exclude_projects ~include_objectives
      ~exclude_objectives ~include_krs ~exclude_krs ~include_engineers
      ~exclude_engineers ()
  in
  Term.(
    pure f
    $ include_projects
    $ exclude_projects
    $ include_objectives
    $ exclude_objectives
    $ include_krs
    $ exclude_krs
    $ include_engineers
    $ exclude_engineers)

let setup () =
  let open Let_syntax_cmdliner in
  let+ style_renderer = Fmt_cli.style_renderer ()
  and+ level = Logs_cli.level () in
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  Fmt_tty.setup_std_outputs ?style_renderer ()

let get_or_error = function
  | Ok v -> v
  | Error (`Msg m) ->
      Fmt.epr "%s" m;
      exit 1

let conf =
  let load okra_file =
    match get_or_error @@ Bos.OS.File.exists (Fpath.v okra_file) with
    | false -> Conf.default
    | true -> get_or_error @@ Conf.load okra_file
  in
  Term.(pure load $ Conf.cmdliner)

(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
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

type t = {
  include_sections : string list;
  ignore_sections : string list;
  files : string list;
}

open Cmdliner

let files_term = Arg.(value & pos_all non_dir_file [] & info [] ~docv:"FILE")

let include_sections_term =
  let info =
    Arg.info [ "include-sections" ]
      ~doc:
        "If non-empty, only lint entries under these sections - everything \
         else is ignored."
  in
  Arg.value (Arg.opt (Arg.list Arg.string) [] info)

let ignore_sections_term =
  let info =
    Arg.info [ "ignore-sections" ]
      ~doc:"If non-empty, don't lint entries under the specified sections."
  in
  Arg.value (Arg.opt (Arg.list Arg.string) [ "OKR updates" ] info)

let engineer_term =
  let info =
    Arg.info [ "engineer"; "e" ]
      ~doc:
        "Lint an engineer report. This is an alias for \
         --include-sections=\"last week\", --ignore-sections=\"\""
  in
  Arg.value (Arg.flag info)

let team_term =
  let info =
    Arg.info [ "team"; "t" ]
      ~doc:
        "Lint a team report. This is an alias for --include-sections=\"\", \
         --ignore-sections=\"OKR updates\""
  in
  Arg.value (Arg.flag info)

let run conf =
  try
    if List.length conf.files > 0 then
      List.iter
        (fun f ->
          let ic = open_in f in
          try
            let res =
              Okra.Lint.lint ~include_sections:conf.include_sections
                ~ignore_sections:conf.ignore_sections ic
            in
            if res <> Okra.Lint.No_error then (
              Printf.fprintf stderr "Error(s) in file %s:\n\n%s" f
                (Okra.Lint.string_of_result res);
              close_in ic;
              exit 1)
            else ();
            close_in ic
          with e ->
            close_in_noerr ic;
            raise e)
        conf.files
    else
      let res =
        Okra.Lint.lint ~include_sections:conf.include_sections
          ~ignore_sections:conf.ignore_sections stdin
      in
      if res <> Okra.Lint.No_error then (
        Printf.fprintf stderr "Error(s) in input stream:\n\n%s"
          (Okra.Lint.string_of_result res);
        exit 1)
      else ()
  with e ->
    Printf.fprintf stderr "Caught unknown error while linting:\n\n";
    raise e

let conf_term =
  let open Let_syntax_cmdliner in
  let+ include_sections = include_sections_term
  and+ ignore_sections = ignore_sections_term
  and+ files = files_term in
  { include_sections; ignore_sections; files }

let term =
  let open Let_syntax_cmdliner in
  let+ conf = conf_term and+ engineer = engineer_term and+ team = team_term in
  let conf =
    if engineer then
      { conf with include_sections = [ "Last week" ]; ignore_sections = [] }
    else if team then { conf with ignore_sections = [ "OKR updates" ] }
    else conf
  in
  run conf

let cmd =
  let info =
    Term.info "lint"
      ~doc:"Check for formatting errors and missing information in the report"
      ~man:
        [
          `S Manpage.s_description;
          `P
            "Check for general formatting errors, then attempt to parse the \
             report and look for inconsistencies.";
          `P "Reads from stdin if no files are specified.";
        ]
  in
  (term, info)

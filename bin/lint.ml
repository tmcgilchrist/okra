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

let with_in_file path f =
  let ic = Stdlib.open_in path in
  Fun.protect ~finally:(fun () -> Stdlib.close_in_noerr ic) (fun () -> f ic)

let run conf =
  let collect_errors name ic =
    match
      Okra.Lint.lint ~include_sections:conf.include_sections
        ~ignore_sections:conf.ignore_sections ic
    with
    | Ok () -> []
    | Error e -> [ (name, e) ]
  in
  let report_error name e =
    Printf.fprintf stderr "Error(s) in %s:\n\n%s" name
      (Okra.Lint.string_of_error e)
  in
  try
    let errors =
      if conf.files <> [] then
        List.concat_map
          (fun path ->
            with_in_file path (fun ic ->
                let name = Printf.sprintf "file %s" path in
                collect_errors name ic))
          conf.files
      else collect_errors "input stream" stdin
    in
    List.iter (fun (name, error) -> report_error name error) errors;
    if errors <> [] then exit 1
  with e ->
    Printf.fprintf stderr "Caught unknown error while linting:\n\n";
    raise e

let conf_term =
  let open Let_syntax_cmdliner in
  let+ include_sections = include_sections_term
  and+ ignore_sections = ignore_sections_term
  and+ files = Common.files
  and+ () = Common.setup () in
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

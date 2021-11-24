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

type format = Short | Pretty

type t = {
  include_sections : string list;
  ignore_sections : string list;
  files : string list;
  format : format;
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

let green = Fmt.(styled `Green string)
let red = Fmt.(styled `Red string)
let pp_status style ppf s = Fmt.(pf ppf "[%a]" style s)

let run conf =
  let collect_errors name ic =
    match
      Okra.Lint.lint ~include_sections:conf.include_sections
        ~ignore_sections:conf.ignore_sections ic
    with
    | Ok () -> [ (name, None) ]
    | Error e -> [ (name, Some e) ]
  in
  let report_error name e =
    match conf.format with
    | Pretty ->
        Fmt.(
          pf stderr "%a: %s\n\n%s" (pp_status red) "ERROR(S)" name
            (Okra.Lint.string_of_error e))
    | Short ->
        List.iter print_endline (Okra.Lint.short_messages_of_error name e)
  in
  let report_ok name =
    match conf.format with
    | Pretty -> Fmt.pr "%a: %s\n%!" (pp_status green) "OK" name
    | Short -> ()
  in
  try
    let errors =
      if conf.files <> [] then
        List.concat_map
          (fun path -> with_in_file path (fun ic -> collect_errors path ic))
          conf.files
      else collect_errors "<stdin>" stdin
    in
    let correct, errors =
      List.fold_left
        (fun (correct, errors) (name, err) ->
          match err with
          | Some err -> (correct, (name, err) :: errors)
          | None -> (name :: correct, errors))
        ([], []) errors
    in
    List.iter report_ok (List.rev correct);
    List.iter (fun (name, error) -> report_error name error) (List.rev errors);
    if errors <> [] then exit 1
  with e ->
    Printf.fprintf stderr "Caught unknown error while linting:\n\n";
    raise e

let format_term =
  let open Let_syntax_cmdliner in
  let+ short =
    Arg.(
      value
      & Arg.flag
      & Arg.info
          ~doc:
            "Output to stdout and emit one line per error,\n\
             using the format `file:line:message`."
          [ "short" ])
  in
  if short then Short else Pretty

let conf_term =
  let open Let_syntax_cmdliner in
  let+ include_sections = include_sections_term
  and+ ignore_sections = ignore_sections_term
  and+ files = Common.files
  and+ format = format_term
  and+ () = Common.setup () in
  { include_sections; ignore_sections; files; format }

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

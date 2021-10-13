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

type t = {
  show_time : bool;
  show_time_calc : bool;
  show_engineers : bool;
  ignore_sections : string list;
  include_sections : string list;
  filter : Okra.Report.filter;
  files : string list;
  in_place : bool;
  output : string option;
  okr_db : string option;
}

open Cmdliner

let show_time_term =
  let info =
    Arg.info [ "show-time" ] ~doc:"Include engineering time in output"
  in
  Arg.value (Arg.opt Arg.bool true info)

let show_time_calc_term =
  let info =
    Arg.info [ "show-time-calc" ]
      ~doc:
        "Include intermediate time calculations in output, showing each time \
         entry found with a sum at the end. This is useful for debugging when \
         aggregating reports for multiple weeks."
  in
  Arg.value (Arg.opt Arg.bool false info)

let show_engineers_term =
  let info =
    Arg.info [ "show-engineers" ] ~doc:"Include a list of engineers per KR"
  in
  Arg.value (Arg.opt Arg.bool true info)

let engineer_term =
  let info =
    Arg.info [ "engineer"; "e" ]
      ~doc:
        "Aggregate engineer reports. This is an alias for \
         --include-sections=\"last week\", --ignore-sections=\"\""
  in
  Arg.value (Arg.flag info)

let team_term =
  let info =
    Arg.info [ "team"; "t" ]
      ~doc:
        "Aggregate team reports. This is an alias for --include-sections=\"\", \
         --ignore-sections=\"OKR updates\""
  in
  Arg.value (Arg.flag info)

let okr_db_term =
  let info =
    Arg.info [ "okr-db" ]
      ~doc:
        "Replace KR titles, objectives and projects with information from a \
         CSV. Requires header with columns id,title,objective,project."
  in
  Arg.value (Arg.opt (Arg.some Arg.file) None info)

let read_file f =
  let ic = open_in f in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic;
  s

let run conf =
  let okr_db =
    match conf.okr_db with
    | None -> None
    | Some f -> Some (Okra.Masterdb.load_csv f)
  in
  let md =
    match conf.files with
    | [] -> Omd.of_channel stdin
    | fs ->
        let s = String.concat "\n" (List.map read_file fs) in
        Omd.of_string s
  in
  let oc =
    match conf.output with
    | Some f -> open_out f
    | None -> (
        if not conf.in_place then stdout
        else
          match conf.files with
          | [] -> Fmt.invalid_arg "[-i] needs at list an input file."
          | [ f ] -> open_out f
          | _ -> Fmt.invalid_arg "[-i] needs at most a file.")
  in
  let okrs =
    try
      Okra.Report.of_markdown ~ignore_sections:conf.ignore_sections
        ~include_sections:conf.include_sections ?okr_db md
    with e ->
      Logs.err (fun l ->
          l
            "An error ocurred while parsing the input file(s). Run `lint` for \
             more information.\n\n\
             %s\n"
            (Printexc.to_string e));
      exit 1
  in
  let okrs = Okra.Report.filter conf.filter okrs in
  let pp =
    Okra.Report.pp ~show_time:conf.show_time ~show_time_calc:conf.show_time_calc
      ~show_engineers:conf.show_engineers
  in
  Okra.Printer.to_channel oc pp okrs

let conf_term =
  let open Let_syntax_cmdliner in
  let+ show_time = show_time_term
  and+ show_time_calc = show_time_calc_term
  and+ show_engineers = show_engineers_term
  and+ okr_db = okr_db_term
  and+ filter = Common.filter
  and+ ignore_sections = Common.ignore_sections
  and+ include_sections = Common.include_sections
  and+ files = Common.files
  and+ output = Common.output
  and+ in_place = Common.in_place
  and+ conf = Common.conf
  and+ () = Common.setup () in
  let okr_db =
    match (okr_db, Conf.okr_db conf) with Some x, _ -> Some x | None, x -> x
  in
  {
    show_time;
    show_time_calc;
    show_engineers;
    ignore_sections;
    include_sections;
    filter;
    okr_db;
    files;
    output;
    in_place;
  }

let term =
  let open Let_syntax_cmdliner in
  let+ conf = conf_term and+ team = team_term and+ engineer = engineer_term in
  let conf =
    if engineer then
      { conf with ignore_sections = []; include_sections = [ "Last week" ] }
    else if team then
      { conf with ignore_sections = [ "OKR Updates" ]; include_sections = [] }
    else conf
  in
  run conf

let cmd =
  let info =
    Term.info "cat" ~doc:"parse and concatenate reports"
      ~man:
        [
          `S Manpage.s_description;
          `P
            "Parses one or more OKR reports and outputs a report aggregated \
             per KR. See below for options for modifying the output format.";
        ]
  in
  (term, info)

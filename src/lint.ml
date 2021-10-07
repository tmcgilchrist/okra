(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
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

type lint_error =
  | Format_error of (int * string) list
  | No_time_found of string
  | Invalid_time of string
  | Multiple_time_entries of string
  | No_work_found of string
  | No_KR_ID_found of string
  | No_project_found of string

type lint_result = (unit, lint_error) result

let fail_fmt_patterns =
  [
    (Str.regexp ".*\t", "Tab found. Use spaces for indentation (2 preferred).");
    ( Str.regexp ".*-  ",
      "Double space before text after bullet point ('-  text'), this can \
       confuse the parser. Use '- text'" );
    ( Str.regexp "^ -",
      "Single space used for indentation (' - text'). Remove or replace by 2 \
       or more spaces." );
    ( Str.regexp "^[ ]*\\*",
      "* used as bullet point, this can confuse the parser. Only use - as \
       bullet marker." );
    ( Str.regexp "^[ ]*\\+",
      "+ used as bullet point, this can confuse the parser. Only use - as \
       bullet marker." );
    ( Str.regexp "^[ ]+#",
      "Space found before title marker #. Start titles in first column." );
  ]

let pp_error ppf = function
  | Format_error x ->
      List.iter (fun (pos, msg) -> Fmt.pf ppf "Line %d: %s\n" pos msg) x;
      Fmt.pf ppf "%d formatting errors found. Parsing aborted.\n"
        (List.length x)
  | No_time_found s ->
      Fmt.pf ppf
        "In KR %S:\n\
        \  No time entry found. Each KR must be followed by '- @@... (x days)'\n"
        s
  | Invalid_time s ->
      Fmt.pf ppf
        "In KR %S:\n\
        \  Invalid time entry found. Format is '- @@eng1 (x days), @@eng2 (x \
         days)'\n"
        s
  | Multiple_time_entries s ->
      Fmt.pf ppf
        "In KR %S:\n\
        \  Multiple time entries found. Only one time entry should follow \
         immediately after the KR.\n"
        s
  | No_work_found s ->
      Fmt.pf ppf
        "In KR %S:\n\
        \  No work items found. This may indicate an unreported parsing error. \
         Remove the KR if it is without work.\n"
        s
  | No_KR_ID_found s ->
      Fmt.pf ppf
        "In KR %S:\n\
        \  No KR ID found. KRs should be in the format \"This is a KR \
         (PLAT123)\", where PLAT123 is the KR ID. For KRs that don't have an \
         ID yet, use \"New KR\".\n"
        s
  | No_project_found s ->
      Fmt.pf ppf "In KR %S:\n  No project found (starting with '#')\n" s

let string_of_error = Fmt.to_to_string pp_error

(* Check a single line for formatting errors returning
   a list of error messages with the position *)
let check_line line pos =
  List.fold_left
    (fun acc (regexp, msg) ->
      if Str.string_match regexp line 0 then (pos, msg) :: acc else acc)
    [] fail_fmt_patterns

(* Parse document as a string to check for aggregation errors
   (assumes no formatting errors) *)
let check_document ~include_sections ~ignore_sections s =
  try
    let md = Omd.of_string s in
    let okrs = Parser.of_markdown ~include_sections ~ignore_sections md in
    let _report = Report.of_krs okrs in
    Ok ()
  with
  | Parser.No_time_found s -> Error (No_time_found s)
  | Parser.Invalid_time s -> Error (Invalid_time s)
  | Parser.Multiple_time_entries s -> Error (Multiple_time_entries s)
  | Parser.No_work_found s -> Error (No_work_found s)
  | Parser.No_KR_ID_found s -> Error (No_KR_ID_found s)
  | Parser.No_project_found s -> Error (No_project_found s)

let lint ?(include_sections = []) ?(ignore_sections = []) ic =
  let format_errors = ref [] in
  let rec check_and_read buf ic pos =
    try
      let line = input_line ic in
      format_errors := check_line line pos @ !format_errors;
      Buffer.add_string buf line;
      Buffer.add_string buf "\n";
      check_and_read buf ic (pos + 1)
    with
    | End_of_file -> Buffer.contents buf
    | e -> raise e
  in
  let s = check_and_read (Buffer.create 1024) ic 1 in
  if !format_errors <> [] then
    Error
      (Format_error
         (List.sort (fun (x, _) (y, _) -> compare x y) !format_errors))
  else check_document ~include_sections ~ignore_sections s

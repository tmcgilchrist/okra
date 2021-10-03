(*
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
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
  show_time : bool;
  show_time_calc : bool;
  show_engineers : bool;
  ignore_sections : string list;
  include_sections : string list;
  filter : Okra.Report.Filter.t;
  okr_db : Okra.Masterdb.t option;
}

let default_conf =
  {
    show_time = true;
    show_time_calc = false;
    show_engineers = true;
    ignore_sections = [];
    include_sections = [];
    filter = Okra.Report.Filter.empty;
    okr_db = None;
  }

let run ?(conf = default_conf) files =
  let str =
    List.map
      (fun file ->
        let ic = open_in file in
        really_input_string ic (in_channel_length ic))
      files
  in
  let str = String.concat "\n" str in
  let md = Omd.of_string str in
  let okrs =
    Okra.Report.of_markdown ~ignore_sections:conf.ignore_sections
      ~include_sections:conf.include_sections ?okr_db:conf.okr_db md
  in
  let okrs = Okra.Report.filter conf.filter okrs in
  Okra.Report.print ~show_time:conf.show_time
    ~show_time_calc:conf.show_time_calc ~show_engineers:conf.show_engineers okrs

let () =
  let files =
    List.tl (Array.to_list Sys.argv) |> List.filter (fun f -> f <> "--use-db")
  in
  if files = [] then Fmt.epr "usage: ./test.exe [--use-db] file"
  else
    let conf =
      if Sys.argv |> Array.exists (fun f -> f = "--use-db") then
        let okr_db = Okra.Masterdb.load_csv "db.csv" in
        { default_conf with okr_db = Some okr_db }
      else default_conf
    in
    run ~conf files

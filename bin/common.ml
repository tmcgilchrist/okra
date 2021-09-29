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
  Arg.(value (opt (list string) [] i))

let ignore_sections =
  let i =
    Arg.info [ "ignore-sections" ]
      ~doc:
        "If non-empty, ignore everyhing under these sections (titles) from the \
         report"
  in
  Arg.(value (opt (list string) [ "OKR updates" ] i))

let include_krs =
  let i =
    Arg.info [ "include-krs" ]
      ~doc:"If non-empty, only include this list of KR IDs in the output."
  in
  Arg.(value (opt (list string) [] i))

let setup () =
  let open Let_syntax_cmdliner in
  let+ style_renderer = Fmt_cli.style_renderer ()
  and+ level = Logs_cli.level () in
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  Fmt_tty.setup_std_outputs ?style_renderer ()

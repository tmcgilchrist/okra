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

let aggregate_by_engineer f =
  let ic = open_in f in
  let omd = Omd.of_channel ic in
  let p = Okra.Report.of_markdown omd in
  let res = Okra.Aggregate.by_engineer p in
  close_in ic;
  res

let test_time_parsing f () =
  let res = aggregate_by_engineer f in
  Alcotest.(check (float 0.0)) "eng1 time" 3.0 (Hashtbl.find res "eng1");
  Alcotest.(check (float 0.0)) "eng3 time" 5.0 (Hashtbl.find res "eng3");
  Alcotest.(check (float 0.0)) "eng4 time" 1.5 (Hashtbl.find res "eng4");
  Alcotest.(check (float 0.0)) "eng5 time" 11.0 (Hashtbl.find res "eng5")

let tests =
  [
    ( "Test_time_parsing",
      `Quick,
      test_time_parsing "./aggregate/valid-time1.acc" );
  ]

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

let test_week monday sunday week year () =
  let week = Calendar.of_week ~year week in
  let gen_monday, gen_sunday = Calendar.to_iso8601 week in
  Alcotest.(check string) "same monday" monday gen_monday;
  Alcotest.(check string) "same sunday" sunday gen_sunday

let test_week_range monday sunday week year () =
  let week = Calendar.of_week_range ~year week in
  let gen_monday, gen_sunday = Calendar.to_iso8601 week in
  Alcotest.(check string) "same monday" monday gen_monday;
  Alcotest.(check string) "same sunday" sunday gen_sunday

let test_month first last month year () =
  let month = Calendar.of_month ~year month in
  let gen_first, gen_last = Calendar.to_iso8601 month in
  Alcotest.(check string) "same first" first gen_first;
  Alcotest.(check string) "same last" last gen_last

let tests =
  [
    ( "week_1_2020",
      `Quick,
      test_week "2019-12-30T00:00:00Z" "2020-01-05T23:59:59Z" 1 2020 );
    ( "week_1_2021",
      `Quick,
      test_week "2021-01-04T00:00:00Z" "2021-01-10T23:59:59Z" 1 2021 );
    ( "week_1_2022",
      `Quick,
      test_week "2022-01-03T00:00:00Z" "2022-01-09T23:59:59Z" 1 2022 );
    ( "weeks_1_4_2022",
      `Quick,
      test_week_range "2022-01-03T00:00:00Z" "2022-01-30T23:59:59Z" (1, 4) 2022
    );
    ( "weeks_35_38_2021",
      `Quick,
      test_week_range "2021-08-30T00:00:00Z" "2021-09-26T23:59:59Z" (35, 38)
        2021 );
    ( "week_35_2021",
      `Quick,
      test_week "2021-08-30T00:00:00Z" "2021-09-05T23:59:59Z" 35 2021 );
    ( "month_1_2021",
      `Quick,
      test_month "2021-01-01T00:00:00Z" "2021-01-31T23:59:59Z" 1 2021 );
    ( "month_12_1998",
      `Quick,
      test_month "1998-12-01T00:00:00Z" "1998-12-31T23:59:59Z" 12 1998 );
  ]

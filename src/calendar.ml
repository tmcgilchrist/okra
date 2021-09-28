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

module Cal = CalendarLib.Calendar

type t = { week : int; month : int; year : int }

let week { week; _ } = week
let month { month; _ } = month
let year { year; _ } = year
let day = 60. *. 60. *. 24.

let now () =
  let now = Cal.now () in
  {
    week = Cal.week now;
    month = Cal.month now |> Cal.Date.int_of_month;
    year = Cal.year now;
  }

let this_month = now
let make_week ~week ~year = { week; month = (now ()).month; year }
let this_week = now
let make_month ~month ~year = { week = (now ()).week; month; year }
let make ~week ~month ~year = { week; month; year }

(* ISO8601 compliant: https://en.wikipedia.org/wiki/ISO_week_date#Calculating_an_ordinal_or_month_date_from_a_week_date *)
let monday_of_week week year =
  let fourth =
    Cal.Date.make year 1 4 |> Cal.Date.day_of_week |> Cal.Date.int_of_day
  in
  let monday = Cal.Date.int_of_day Cal.Mon in
  let d = (week * 7) + monday - (fourth + 3) in
  match d with
  | d when d < 1 ->
      let prev = year - 1 in
      let doy = d + Cal.Date.days_in_year prev in
      Cal.Date.from_day_of_year prev doy
  | d when d > Cal.Date.days_in_year year ->
      let doy = d - Cal.Date.days_in_year year in
      Cal.Date.from_day_of_year year doy
  | d -> Cal.Date.from_day_of_year year d

let range_of_week =
  let six_days = Cal.Date.Period.make 0 0 6 in
  fun t ->
    let monday = monday_of_week t.week t.year in
    (monday, Cal.Date.add monday six_days)

let range_of_month { week = _; month; year } =
  let first = Cal.Date.lmake ~year ~month ~day:1 () in
  let days = Cal.Date.days_in_month first in
  let last = Cal.Date.add first @@ Cal.Date.Period.day days in
  (first, last)

let github_month t =
  let first, last = range_of_month t in
  ( Cal.Date.to_unixfloat first |> Get_activity.Period.to_8601,
    Cal.Date.to_unixfloat last |> Get_activity.Period.to_8601 )

let github_week t =
  let monday, sunday = range_of_week t in
  let sunday =
    (* Some people might work on the sunday... *)
    Cal.Date.to_unixfloat sunday +. (day -. 1.) |> Cal.from_unixfloat
  in
  ( Cal.Date.to_unixfloat monday |> Get_activity.Period.to_8601,
    Cal.to_unixfloat sunday |> Get_activity.Period.to_8601 )

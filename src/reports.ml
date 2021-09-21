(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
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

type kr = {
  counter : int;
  project : string;
  objective : string;
  kr_title : string;
  kr_id : string;
  time_entries : string list;
  time_per_engineer : (string, float) Hashtbl.t;
  work : Item.t list list;
}

type kr_key = { id : string; title : string }
type objective = { name : string; krs : (kr_key, kr) Hashtbl.t }
type project = { name : string; objectives : (string, objective) Hashtbl.t }
type t = (string, project) Hashtbl.t

let compare_objectives (x : objective) (y : objective) =
  String.compare x.name y.name

let compare_projects (x : project) (y : project) = String.compare x.name y.name

let compare_krs a b =
  if
    a.kr_id = ""
    || b.kr_id = ""
    || a.kr_id = "NEW KR"
    || b.kr_id = "NEW KR"
    || a.kr_id = "NEW OKR"
    || b.kr_id = "NEW OKR"
  then String.compare a.kr_title b.kr_title
  else
    String.compare
      (String.capitalize_ascii a.kr_id)
      (String.capitalize_ascii b.kr_id)

let v entries =
  let v = Hashtbl.create 13 in
  let add e =
    let p =
      match Hashtbl.find_opt v e.project with
      | Some p -> p
      | None ->
          let p = { name = e.project; objectives = Hashtbl.create 13 } in
          Hashtbl.add v e.project p;
          p
    in
    let o =
      match Hashtbl.find_opt p.objectives e.objective with
      | Some o -> o
      | None ->
          let o = { name = e.objective; krs = Hashtbl.create 13 } in
          Hashtbl.add p.objectives e.objective o;
          o
    in
    Hashtbl.add o.krs { id = e.kr_id; title = e.kr_title } e
  in
  List.iter add entries;
  v

let make_days d =
  let d = floor (d *. 2.0) /. 2. in
  if d = 1. then "1 day"
  else if classify_float (fst (modf d)) = FP_zero then
    Printf.sprintf "%.0f days" d
  else Printf.sprintf "%.1f days" d

let make_engineer ~time (e, d) =
  if time then Printf.sprintf "@%s (%s)" e (make_days d)
  else Printf.sprintf "@%s" e

let make_engineers ~time entries =
  let entries = List.of_seq (Hashtbl.to_seq entries) in
  let entries = List.sort (fun (x, _) (y, _) -> String.compare x y) entries in
  let engineers = List.rev_map (make_engineer ~time) entries in
  match engineers with
  | [] -> []
  | e :: es ->
      let open Item in
      let lst =
        List.fold_left
          (fun acc engineer -> Text engineer :: Text ", " :: acc)
          [ Text e ] es
      in
      [ Paragraph (Concat lst) ]

type config = {
  show_engineers : bool;
  show_time : bool;
  show_time_calc : bool;
  include_krs : string list;
}

let make_kr conf kr =
  let open Item in
  if
    List.length conf.include_krs <> 0
    && not (List.mem kr.kr_id conf.include_krs)
  then []
  else
    let items =
      if not conf.show_engineers then []
      else if conf.show_time then
        if conf.show_time_calc then
          (* show time calc + engineers *)
          [
            List
              ( Bullet '+',
                List.map (fun x -> [ Paragraph (Text x) ]) kr.time_entries );
            List (Bullet '=', [ make_engineers ~time:true kr.time_per_engineer ]);
          ]
        else make_engineers ~time:true kr.time_per_engineer
      else make_engineers ~time:false kr.time_per_engineer
    in
    [
      List
        ( Bullet '-',
          [
            [
              Paragraph (Text (Printf.sprintf "%s (%s)" kr.kr_title kr.kr_id));
              List (Bullet '-', items :: kr.work);
            ];
          ] );
    ]

let make_objective conf o =
  let krs = List.of_seq (Hashtbl.to_seq o.krs |> Seq.map snd) in
  let krs = List.sort compare_krs krs in
  match List.concat_map (make_kr conf) krs with
  | [] -> []
  | krs -> Item.Title (2, o.name) :: krs

let make_project conf p =
  let os = List.of_seq (Hashtbl.to_seq p.objectives |> Seq.map snd) in
  let os = List.sort compare_objectives os in
  match List.concat_map (make_objective conf) os with
  | [] -> []
  | os -> Item.Title (1, p.name) :: os

let pp ?(include_krs = []) ?(show_time = true) ?(show_time_calc = true)
    ?(show_engineers = true) ppf t =
  let conf =
    {
      show_time;
      show_time_calc;
      show_engineers;
      include_krs = List.map String.uppercase_ascii include_krs;
    }
  in
  let ps = List.of_seq (Hashtbl.to_seq t |> Seq.map snd) in
  let ps = List.sort compare_projects ps in
  let doc = List.concat_map (make_project conf) ps in
  Printer.list ~sep:Printer.(newline ++ newline) Item.pp ppf doc;
  Printer.newline ppf ()

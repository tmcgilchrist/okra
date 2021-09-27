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

let src = Logs.Src.create "okra.report"

module Log = (val Logs.src_log src : Logs.LOG)

type objective = {
  name : string;
  (* by IDs *) krs : (string, KR.t) Hashtbl.t;
  (* by title *) new_krs : (string, KR.t) Hashtbl.t;
}

type project = { name : string; objectives : (string, objective) Hashtbl.t }
type t = (string, project) Hashtbl.t

let compare_no_case x y =
  String.compare (String.uppercase_ascii x) (String.uppercase_ascii y)

let find_no_case t k = Hashtbl.find_opt t (String.uppercase_ascii k)
let add_no_case t k v = Hashtbl.add t (String.uppercase_ascii k) v
let replace_no_case t k v = Hashtbl.replace t (String.uppercase_ascii k) v
let remove_no_case t k = Hashtbl.remove t (String.uppercase_ascii k)

let iter_objective f t =
  Hashtbl.iter (fun _ kr -> f kr) t.krs;
  Hashtbl.iter (fun _ kr -> f kr) t.new_krs

let iter_project f t =
  Hashtbl.iter (fun _ os -> iter_objective f os) t.objectives

let iter f t = Hashtbl.iter (fun _ ps -> iter_project f ps) t
let dump ppf t = Fmt.iter iter KR.dump ppf t

let compare_objectives (x : objective) (y : objective) =
  compare_no_case x.name y.name

let compare_projects (x : project) (y : project) = compare_no_case x.name y.name

let add (t : t) (e : KR.t) =
  Log.debug (fun l -> l "Report.add %a %a" dump t KR.dump e);
  let p =
    match find_no_case t e.project with
    | Some p -> p
    | None ->
        let p = { name = e.project; objectives = Hashtbl.create 13 } in
        add_no_case t e.project p;
        p
  in
  let o =
    match find_no_case p.objectives e.objective with
    | Some o -> o
    | None ->
        let o =
          {
            name = e.objective;
            krs = Hashtbl.create 13;
            new_krs = Hashtbl.create 13;
          }
        in
        add_no_case p.objectives e.objective o;
        o
  in
  let existing_kr =
    match e.id with
    | None -> find_no_case o.krs e.title
    | Some id -> (
        match find_no_case o.krs id with
        | None -> find_no_case o.new_krs e.title
        | Some kr -> Some kr)
  in
  let merge_kr =
    match existing_kr with None -> e | Some kr -> KR.merge e kr
  in
  match merge_kr.id with
  | None -> replace_no_case o.new_krs e.title merge_kr
  | Some id ->
      remove_no_case o.new_krs e.title;
      replace_no_case o.krs id merge_kr

let v entries =
  let t = Hashtbl.create 13 in
  List.iter (add t) entries;
  t

let of_markdown ?ignore_sections ?include_sections m =
  v (Parser.of_markdown ?ignore_sections ?include_sections m)

let make_objective conf o =
  let krs = List.of_seq (Hashtbl.to_seq o.krs |> Seq.map snd) in
  let new_krs = List.of_seq (Hashtbl.to_seq o.new_krs |> Seq.map snd) in
  let krs = List.sort KR.compare krs @ List.sort KR.compare new_krs in
  match List.concat_map (KR.items conf) krs with
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
      KR.show_time;
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

let print ?include_krs ?show_time ?show_time_calc ?show_engineers t =
  let pp = pp ?include_krs ?show_time ?show_time_calc ?show_engineers in
  Printer.to_stdout pp t

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

type kind = Projects | Objectives | KRs

type t = {
  ignore_sections : string list;
  include_sections : string list;
  include_krs : string list;
  kind : kind;
}

open Okra

(* show largest work items first *)
let sort_by_days l =
  let aux (_, x) (_, y) = compare y x in
  List.sort aux l

let print kind t =
  match kind with
  | Projects ->
      let projects =
        Aggregate.by_project t |> Hashtbl.to_seq |> List.of_seq |> sort_by_days
      in
      List.iter
        (fun (p_name, d) ->
          let d = KR.string_of_days d in
          Fmt.pr "# %s: %s\n" p_name d)
        projects
  | Objectives ->
      let objectives =
        Aggregate.by_objective t
        |> Hashtbl.to_seq
        |> List.of_seq
        |> sort_by_days
      in
      List.iter
        (fun (o_name, d) ->
          let d = KR.string_of_days d in
          let ps = Report.Objective.find_all t o_name in
          let o =
            String.concat "|"
              (List.map (fun (p, _) -> Report.Project.name p) ps)
          in
          Fmt.pr "## [%s] %s %s\n" o o_name d)
        objectives
  | KRs ->
      let krs =
        Aggregate.by_kr t |> Hashtbl.to_seq |> List.of_seq |> sort_by_days
      in
      List.iter
        (fun ((title, id), d) ->
          let d = KR.string_of_days d in
          let id = match id with None -> "New KR" | Some s -> s in
          let ps = Report.find t ~title ~id () in
          let p =
            String.concat "|"
              (List.map
                 (fun kr -> Fmt.strf "%s: %s" kr.KR.project kr.KR.objective)
                 ps)
          in
          Fmt.pr "- [%s] %s (%s): %s\n" p title id d)
        krs

let run conf =
  let md = Omd.of_channel stdin in
  let okrs =
    Okra.Report.of_markdown ~ignore_sections:conf.ignore_sections
      ~include_sections:conf.include_sections md
  in
  print conf.kind okrs

open Cmdliner

let kind =
  let i = Arg.info [ "kind" ] in
  let ks =
    Arg.enum
      [ ("projects", Projects); ("objectives", Objectives); ("krs", KRs) ]
  in
  Arg.(value (opt ks KRs i))

let conf_term =
  let open Let_syntax_cmdliner in
  let+ include_krs = Common.include_krs
  and+ ignore_sections = Common.ignore_sections
  and+ include_sections = Common.include_sections
  and+ kind = kind in
  { ignore_sections; include_sections; include_krs; kind }

let term =
  let open Let_syntax_cmdliner in
  let+ conf = conf_term in
  run conf

let cmd =
  let info = Term.info "stats" ~doc:"show OKR statistics" in
  (term, info)

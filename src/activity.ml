(*
 * Copyright (c) 2021 Patrick Ferris <pf341@patricoferris.com>
 * Copyright (c) 2021 Tim McGilchrist <timmcgil@gmail.com>
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

type project = { title : string; items : string list }

let title { title; _ } = title

type t = { projects : project list; activity : Get_activity.Contributions.t }

let pp_last_week username ppf projects =
  let pp_items ppf t =
    let t = if t = [] then [ "Work Item 1" ] else t in
    Fmt.(pf ppf "%a" (list (fun ppf s -> Fmt.pf ppf "  - %s" s))) t
  in
  let pp_project ppf { title; items } =
    Fmt.pf ppf "- %s\n  - @%s (<X> days)\n%a@." title username pp_items items
  in
  Fmt.pf ppf "%a" Fmt.(list ~sep:(cut ++ cut) pp_project) projects

let repo_org ?(with_id = false) ?(no_links = false) f s =
  let remove_hash s =
    match String.split_on_char '#' s with
    | [ i ] -> i (* Normal PR or Issue ids *)
    | i :: _ -> i (* Extracted from PR reviews *)
    | _ -> failwith "Malformed URL trying to get id number"
  in
  match String.split_on_char '/' s |> List.rev with
  (* URLs with ids have the form (in reverse) <id>/<kind>/<repo>/<org>/... *)
  | i :: _ :: repo :: org :: _ when with_id ->
      if no_links then Fmt.pf f "%s/%s#%s" org repo i
      else Fmt.pf f "[%s/%s#%s](%s)" org repo (remove_hash i) s
  (* For now the only kind like this are new repository creations *)
  | repo :: org :: _ -> Fmt.pf f "[%s/%s](%s)" org repo s
  | _ -> Fmt.failwith "Malformed URL %S" s

let pp_ga_item ~no_links f (t : Get_activity.Contributions.item) =
  match t.kind with
  | `Issue ->
      Fmt.pf f "Issue: %s %a" t.title (repo_org ~with_id:true ~no_links) t.url
  | `PR -> Fmt.pf f "PR: %s %a" t.title (repo_org ~with_id:true ~no_links) t.url
  | `Review s ->
      Fmt.pf f "%s %s %a" s t.title (repo_org ~with_id:true ~no_links) t.url
  | `New_repo ->
      Fmt.pf f "Created repository %a"
        (repo_org ~with_id:false ~no_links:false)
        t.url

let pp_activity ~no_links ppf activity =
  let open Get_activity.Contributions in
  let pp_item ppf item = Fmt.pf ppf "  - %a" (pp_ga_item ~no_links) item in
  let bindings = Repo_map.bindings activity in
  let pp_binding ppf (_repo, items) =
    Fmt.pf ppf "%a" Fmt.(list pp_item) items
  in
  Fmt.pf ppf "%a" Fmt.(list pp_binding) bindings

let make ~projects activity = { projects; activity }

let pp ?(no_links = false) ppf { projects; activity = { username; activity } } =
  Fmt.pf ppf
    {|# Projects

%a

# Last Week

%a
# Activity (move these items to last week)

%a
|}
    Fmt.(list (fun ppf s -> Fmt.pf ppf "- %s" s))
    (List.map title projects) (pp_last_week username) projects
    (pp_activity ~no_links) activity

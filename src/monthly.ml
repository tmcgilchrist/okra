type project = { title : string; description : string; repos : string list }

let owner_name s =
  match Astring.String.cut ~sep:"/" s with
  | Some t -> t
  | None -> failwith "failed to get owner and name"

module U = Yojson.Safe.Util

let ( / ) a b = U.member b a
let ( // ) a b = try Some (U.member b a) with _ -> None
let underscore s = String.split_on_char '-' s |> String.concat "_"

module Issue = struct
  type t = {
    author : string option;
    title : string;
    url : string;
    body : string;
    closed : bool;
    closed_at : string option;
    created_at : string;
  }

  let parse json =
    let author = Option.map U.to_string @@ (json / "author" // "login") in
    let url = json / "url" |> U.to_string in
    let body = json / "body" |> U.to_string in
    let title = json / "title" |> U.to_string in
    let closed = json / "closed" |> U.to_bool in
    let created_at = json / "createdAt" |> U.to_string in
    let closed_at = json / "closedAt" |> U.to_string_option in
    { author; title; url; body; closed; closed_at; created_at }

  let pp ppf { author; title; url; created_at; _ } =
    Fmt.(
      pf ppf "- [%s](%s) by @%s\n\n   (created: %s)\n" title url
        (Option.value ~default:"No author" author)
        created_at)
end

module PR = struct
  type t = {
    author : string option;
    cursor : string;
    url : string;
    title : string;
    body : string;
    closed : bool;
    closed_at : string option;
    created_at : string;
    is_draft : bool;
    merged_at : string option;
    reviewers : string list;
  }

  let parse json =
    let cursor = json / "cursor" |> U.to_string in
    let json = json / "node" in
    let author = Option.map U.to_string @@ (json / "author" // "login") in
    let url = json / "url" |> U.to_string in
    let body = json / "body" |> U.to_string in
    let title = json / "title" |> U.to_string in
    let closed = json / "closed" |> U.to_bool in
    let created_at = json / "createdAt" |> U.to_string in
    let closed_at = json / "closedAt" |> U.to_string_option in
    let is_draft = json / "isDraft" |> U.to_bool in
    let merged_at = json / "mergedAt" |> U.to_string_option in
    let reviewers =
      json / "reviews" / "nodes"
      |> U.to_list
      |> List.map (fun v -> v / "author" / "login" |> U.to_string)
      |> List.sort_uniq String.compare
    in
    {
      author;
      url;
      cursor;
      body;
      title;
      closed;
      closed_at;
      created_at;
      is_draft;
      merged_at;
      reviewers;
    }

  let split_by_status ts =
    let split (opened, merged) t =
      if Option.is_some t.merged_at then (opened, t :: merged)
      else (t :: opened, merged)
    in
    List.fold_left split ([], []) ts

  let pp ppf { author; title; url; created_at; merged_at; reviewers; _ } =
    let pp_user ppf = Fmt.pf ppf "@%s" in
    if reviewers = [] then
      Fmt.(
        pf ppf " - [%s](%s) by %a\n\n   (%s)\n" title url pp_user
          (Option.value ~default:"No author" author)
          (Option.value ~default:("created: " ^ created_at)
             (Option.map (( ^ ) "merged: ") merged_at)))
    else
      Fmt.(
        pf ppf " - [%s](%s) by %a\n\n   (%s, reviewed by: %a)\n" title url
          pp_user
          (Option.value ~default:"No author" author)
          (Option.value ~default:("created: " ^ created_at)
             (Option.map (( ^ ) "merged: ") merged_at))
          Fmt.(list ~sep:(fun ppf _ -> Fmt.pf ppf ", ") pp_user)
          reviewers)

  (* The Gihub Graphql API doesn't let you specify a from and to
     for accessing PRs or issues so we have paginate our way back
     to from if that is necessary. The way to do this is with the
     cursor *)
  let query =
    {| pullRequests (last:100, orderBy: { direction: ASC, field: CREATED_AT }, before: $before) {
    edges {
      cursor
      node {
        author {
          login
        }
        url
        title
        body
        closed
        closedAt
        createdAt
        isDraft
        merged
        mergedAt
        reviews (last: 100) {
          nodes {
            author {
              login
            }
          }
        }
      }
    }
  } |}
end

type data = {
  repo : string;
  description : string;
  issues : Issue.t list;
  prs : PR.t list;
}

let project_query ~owner name =
  Fmt.str
    {| %s: repository(owner: "%s", name: "%s") {
    description
    issues (first:100, filterBy: {since: $from}) {
      nodes {
        author {
          login
        }
        url
        title
        body
        closed
        closedAt
        createdAt
      }
    }
    %s
  } |}
    (underscore name) owner name PR.query

let query projects =
  Fmt.str {| query($from: DateTime!, $before: String) {
  %s
} |}
    (List.map (fun (owner, name) -> project_query ~owner name) projects
    |> String.concat "\n")

let pp_data ppf (data : data) =
  let pp_prs ppf prs =
    let opened, merged = PR.split_by_status prs in
    Fmt.pf ppf
      "### Opened (and not merged in same time frame)\n\n%a### Merged\n\n%a"
      Fmt.(list PR.pp)
      opened
      Fmt.(list PR.pp)
      merged
  in
  Fmt.pf ppf "# %s\n%s\n\n## Pull Requests\n\n%a\n\n## Issues\n\n%a" data.repo
    data.description pp_prs data.prs
    Fmt.(list Issue.pp)
    data.issues

module Project_map = Map.Make (String)

type t = data Project_map.t

let parse_data (from, to_) repo json =
  let project = json / "data" / repo in
  let description = project / "description" |> U.to_string in
  let issues =
    project / "issues" / "nodes"
    |> U.to_list
    |> List.map Issue.parse
    |> List.filter (fun issue ->
           issue.Issue.created_at >= from && issue.Issue.created_at <= to_)
  in
  let prs =
    project / "pullRequests" / "edges" |> U.to_list |> List.map PR.parse
  in
  let need_more_prs =
    match prs with
    (* assertion: created_at < merged_at *)
    | { created_at; cursor; _ } :: _ -> (from < created_at, Some cursor)
    | [] -> (false, None)
  in
  let filter_prs from to_ { PR.created_at; merged_at; _ } =
    let time = Option.value ~default:created_at merged_at in
    time >= from && time <= to_
  in
  ( need_more_prs,
    { repo; description; issues; prs = List.filter (filter_prs from to_) prs }
  )

let add_list s v t = Project_map.add s v t

module Make (C : Cohttp_lwt.S.Client) = struct
  module Fetch = Get_activity.Graphql.Make (C)

  let exec ?before ~period:(start, _finish) ~token query =
    let variables =
      [
        ("from", `String start); ("before", Option.value ~default:`Null before);
      ]
    in
    Fetch.exec token ~variables query

  let merge_data datas =
    let first, rest =
      match datas with x :: rest -> (x, rest) | _ -> failwith "No data found!"
    in
    let data =
      List.fold_left
        (fun d { prs; issues; _ } ->
          { d with prs = d.prs @ prs; issues = d.issues @ issues })
        first rest
    in
    (* Issues have a filterBy argument which means we can get exactly the right data in one API call.
       For PRs we are not so lucky, which is where the cursor-based pagination logic comes in. We end
       up duplicating as many times as we make an API call the issues as it uses the same Graphql query.
       So here we filter them out. *)
    {
      data with
      issues =
        List.sort_uniq
          (fun v1 v2 -> String.compare v1.Issue.title v2.title)
          data.issues;
    }

  let get ~period ~token repos =
    let open Lwt.Syntax in
    let open Lwt.Infix in
    let repos = List.map owner_name repos in
    let* json = exec ~period ~token (query repos) in
    let rec parse acc period name json =
      match parse_data period name json with
      | (true, Some cursor), data ->
          let* json =
            exec ~before:(`String cursor) ~period ~token (query repos)
          in
          parse (data :: acc) period name json
      | _, data ->
          if acc = [] then Lwt.return data
          else Lwt.return (merge_data (data :: acc))
    in
    let map = Project_map.empty in
    let+ lst =
      Lwt_list.fold_left_s
        (fun m (_, name) ->
          parse [] period name json >|= fun v -> add_list name v m)
        map repos
    in
    Project_map.bindings lst
end

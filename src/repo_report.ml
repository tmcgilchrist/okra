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
    cursor : string;
    url : string;
    body : string;
    closed : bool;
    closed_at : string option;
    created_at : string;
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
    { author; cursor; title; url; body; closed; closed_at; created_at }

  let pp ppf { author; title; url; created_at; _ } =
    Fmt.(
      pf ppf "- [%s](%s) by @%s\n\n   (created: %s)\n" title url
        (Option.value ~default:"No author" author)
        created_at)

  let query =
    {| issues (last:100, orderBy: { direction: ASC, field: CREATED_AT }, before: $before_issue) {
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
      }
    }
  } |}
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
    {| pullRequests (last:100, orderBy: { direction: ASC, field: CREATED_AT }, before: $before_pr) {
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
  description : string option;
  issues : Issue.t list;
  prs : PR.t list;
}

let project_query ~owner name =
  Fmt.str
    {| %s: repository(owner: "%s", name: "%s") {
    description
    %s
    %s
  } |}
    (underscore name) owner name Issue.query PR.query

let query projects =
  Fmt.str {| query($before_issue: String, $before_pr: String) {
  %s
} |}
    (List.map (fun (owner, name) -> project_query ~owner name) projects
    |> String.concat "\n")

let pp_data ppf (data : data) =
  let pp_prs ppf prs =
    let opened, merged = PR.split_by_status prs in
    Fmt.pf ppf
      "### Opened (and not merged in same time frame)\n\n%a\n\n### Merged\n\n%a"
      Fmt.(list PR.pp)
      (List.sort
         (fun v1 v2 -> String.compare v1.PR.created_at v2.created_at)
         opened)
      Fmt.(list PR.pp)
      (List.sort
         (fun v1 v2 ->
           String.compare (Option.get v1.PR.merged_at) (Option.get v2.merged_at))
         merged)
  in
  Fmt.pf ppf "# %s\n%s\n\n## Pull Requests\n\n%a\n\n## Issues\n\n%a" data.repo
    (Option.value ~default:"No description" data.description)
    pp_prs data.prs
    Fmt.(list Issue.pp)
    (List.sort
       (fun v1 v2 -> String.compare v1.Issue.created_at v2.created_at)
       data.issues)

module Project_map = Map.Make (String)

type t = data Project_map.t

let pp ppf t =
  Project_map.bindings t |> List.map snd |> Fmt.(pf ppf "%a" (list pp_data))

let parse_data (from, to_) repo json =
  let project = json / "data" / underscore repo in
  let description = project / "description" |> U.to_string_option in
  let issues =
    project / "issues" / "edges" |> U.to_list |> List.map Issue.parse
  in
  let prs =
    project / "pullRequests" / "edges" |> U.to_list |> List.map PR.parse
  in
  (* We might need to fetch more PRs or issues, so we provide the cursor to
     paginate further back. Somewhat a limitation in the Github API *)
  let need_more_prs =
    match prs with
    | { created_at; cursor; _ } :: _ ->
        if from < created_at then Some (`String cursor) else None
    | [] -> None
  in
  let need_more_issues =
    match issues with
    | { created_at; cursor; _ } :: _ ->
        if from < created_at then Some (`String cursor) else None
    | [] -> None
  in
  let filter_prs from to_ { PR.created_at; merged_at; _ } =
    let time = Option.value ~default:created_at merged_at in
    time >= from && time <= to_
  in
  let filter_issues from to_ { Issue.created_at; _ } =
    created_at >= from && created_at <= to_
  in
  ( need_more_prs,
    need_more_issues,
    {
      repo;
      description;
      issues = List.filter (filter_issues from to_) issues;
      prs = List.filter (filter_prs from to_) prs;
    } )

let add_list s v t = Project_map.add s v t

module Make (C : Cohttp_lwt.S.Client) = struct
  module Fetch = Get_activity.Graphql.Make (C)

  let exec ?before_pr ?before_issue ~period:_ ~token query =
    let variables =
      [
        ("before_pr", Option.value ~default:`Null before_pr);
        ("before_issue", Option.value ~default:`Null before_issue);
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
    {
      data with
      prs =
        List.sort_uniq
          (fun v1 v2 -> String.compare v1.PR.title v2.title)
          data.prs;
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
      | None, None, data ->
          if acc = [] then Lwt.return data
          else Lwt.return (merge_data (data :: acc))
      | before_pr, before_issue, data ->
          let* json =
            (* TODO: we always ask for all the data even if we don't need more issues
               when searching for more PRs (and for every repository). For queries not
               too far in the past, and with not too many repos per query this is okay
               but in the long-term it might be good to drop parts of the query when they
               are done. *)
            exec ?before_pr ?before_issue ~period ~token (query repos)
          in
          parse (data :: acc) period name json
    in
    let map = Project_map.empty in
    Lwt_list.fold_left_s
      (fun m (_, name) ->
        parse [] period name json >|= fun v -> add_list name v m)
      map repos
end

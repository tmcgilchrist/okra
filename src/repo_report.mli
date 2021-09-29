module Issue : sig
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

  val parse : Yojson.Safe.t -> t
  (** Parses the json received from the Github Graphql API *)

  val pp : t Fmt.t
  (** Prints the issue to a markdown format *)
end

module PR : sig
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

  val split_by_status : t list -> t list * t list
  (** Splits a list of PRs into two lists [opened, merged] *)

  val parse : Yojson.Safe.t -> t
  (** Parses the json received from the Github Graphql API *)

  val pp : t Fmt.t
  (** Prints the issue to a markdown format *)

  val query : string
  (** Graphql query for PRs *)
end

type data = {
  repo : string;
  description : string;
  issues : Issue.t list;
  prs : PR.t list;
}
(** A type for the data about a single repository *)

module Project_map : Map.S with type key := string

type t = data Project_map.t
(** A map from repositories to their PR/issue data *)

module Make (C : Cohttp_lwt.S.Client) : sig
  val get :
    period:string * string ->
    token:string ->
    string list ->
    data Project_map.t Lwt.t
  (** [get ~period ~token repos] gets the information for [repos] over the
      specified [period] using the Github [token] *)
end

val pp : t Fmt.t
(** Prints a markdown formatted view of the data *)

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

let xdg =
  Xdg.create
    ~env:(fun x -> try Some (Unix.getenv x) with Not_found -> None)
    ()

let config_dir =
  let ( / ) = Filename.concat in
  Xdg.config_dir xdg / "okra"

let default_project = { Activity.title = "TODO ADD KR (ID)"; items = [] }

type project = Activity.project = {
  title : string;
  items : string list; [@default []]
}
[@@deriving yaml]
type t = {
  projects : project list; [@default [ default_project ]]
  locations : string list;
  locations : string list; [@default []]
  footer : string option;
  okr_db : string option;
  gitlab_token : string option;
}

let default =
  {
    projects = [ default_project ];
    locations = [];
    footer = None;
    okr_db = None;
    gitlab_token = None;
  }

let projects { projects; _ } = projects
let locations { locations; _ } = locations
let footer { footer; _ } = footer
let okr_db t = t.okr_db
let gitlab_token t = t.gitlab_token

let load file =
  let open Rresult in
  Bos.OS.File.read (Fpath.v file) >>= fun contents ->
  Yaml.of_string contents >>= fun yaml -> of_yaml yaml

let default_file_path =
  let ( / ) = Filename.concat in
  config_dir / "conf.yaml"

open Cow
open Printf
open Lwt

open Data.People
open Data.Wiki
open Cowabloga.Wiki

let num = num_of_entries entries

let cmp_ent a b = Atom.compare (atom_date a.updated) (atom_date b.updated)

let entries = List.rev (List.sort cmp_ent entries)
let _ = List.iter (fun x -> Printf.printf "ENT: %s\n%!" x.subject) entries

let permalink_exists x = List.exists (fun e -> e.permalink = x) entries

let atom_entry_of_ent filefn e =
  let links = [
    Atom.mk_link ~rel:`alternate ~typ:"text/html"
      (Local_uri.mk_uri (permalink e))
  ] in
  lwt content = body_of_entry filefn e in
  let meta = {
    Atom.id      = Local_uri.mk_uri_string (permalink e);
    title        = e.subject;
    subtitle     = None;
    author       = Some e.author;
    updated      = atom_date e.updated;
    links;
    rights =       Data.rights;
  } in
  return {
    Atom.entry = meta;
    summary    = None;
    base       = None;
    content
  }

let atom_feed filefn es =
  let es = List.rev (List.sort cmp_ent es) in
  let updated = atom_date (List.hd es).updated in
  let id = Local_uri.mk_uri_string "/wiki/" in
  let title = "openmirage wiki" in
  let subtitle = Some "a cloud operating system" in
  let links = [
    Atom.mk_link (Local_uri.mk_uri "/wiki/atom.xml");
    Atom.mk_link ~rel:`alternate ~typ:"text/html" (Local_uri.mk_uri "/wiki/")
  ] in
  let feed = { Atom.id; title; subtitle; author=None; rights=Data.rights; updated; links} in
  lwt entries = Lwt_list.map_s (atom_entry_of_ent filefn) es in
  return { Atom.feed=feed; entries }

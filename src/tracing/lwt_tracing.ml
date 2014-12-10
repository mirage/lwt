(* Lightweight thread library for OCaml
 * http://www.ocsigen.org/lwt
 * Interface Lwt_tracing
 * Copyright (C) 2014 Thomas Leonard
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, with linking exceptions;
 * either version 2.1 of the License, or (at your option) any later
 * version. See COPYING file for details.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 *)

type thread_id = int64

type thread_type =
  | Wait
  | Task
  | Bind
  | Try
  | Choose
  | Pick
  | Join
  | Map
  | Condition

type tracer = {
  note_created : thread_id -> thread_type -> unit;
  note_read : thread_id -> unit;
  note_resolved : thread_id -> ex:exn option -> unit;
  note_signal : thread_id -> unit;
  note_becomes : thread_id -> thread_id -> unit;
  note_label : thread_id -> string -> unit;
  note_switch : unit -> unit;
  note_suspend : unit -> unit;
}

let null_tracer =
  let ignore2 _ _ = () in {
    note_created = ignore2;
    note_read = ignore;
    note_resolved = (fun _ ~ex:_ -> ());
    note_signal = ignore;
    note_becomes = ignore2;
    note_label = ignore2;
    note_switch = ignore;
    note_suspend = ignore;
  }

let tracer = ref null_tracer

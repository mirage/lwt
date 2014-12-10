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

(** Module [Lwt_tracing]: provides trace events. *)

(** This module allows a trace event handler to be registered. This
    will be notified whenever significant events happen to a thread.
*)

type thread_id = int64
  (** When Lwt is compiled with tracing support, every thread gets a unique ID. *)

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
  (** [note_created p] indicates when a new thread is created. *)

  note_read : thread_id -> unit;
  (** [note_read p] indicates that the current thread read the resolution of p.
   * e.g. we were waiting for p and p has become resolved.
   * [note_read] implies [note_switch], even if it's not sent, so check [current_id]. *)

  note_resolved : thread_id -> ex:exn option -> unit;
  (** [note_resolves p] indicates that [p] has been resolved (woken).
   * If it resolved to failure, the exception is given too. *)

  note_signal : thread_id -> unit;
  (** [note_signal source] indicates that [source] has signalled the (new) current thread
   * (e.g. with [Lwt_condition.signal].
   * As with [note_read], this implies a switch. *)

  note_becomes : thread_id -> thread_id -> unit;
  (** [note_becomes p1 p2] indicates that the previously-unresolved p1 now behaves as p2. *)

  note_label : thread_id -> string -> unit;
  (** Record a meaningful name for a thread. *)

  note_switch : unit -> unit;
  (** The current thread has changed. *)

  note_suspend : unit -> unit;
  (** The whole application is going to sleep (e.g. calling select()).
   * Call [note_switch] on resume. *)
}

val null_tracer : tracer
  (** A tracer that ignores all events. *)

val tracer : tracer ref
  (** The current tracer. Defaults to [null_tracer]. *)

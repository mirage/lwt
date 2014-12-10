(******************************************************************************)
(* Lightweight thread library for OCaml
 * http://www.ocsigen.org/lwt
 * Module Lwt_condition
 ******************************************************************************
 * Copyright (c) 2009, Metaweb Technologies, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY METAWEB TECHNOLOGIES ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL METAWEB TECHNOLOGIES BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ******************************************************************************)

let (>>=) = Lwt.(>>=)

type 'a t = ('a Lwt.u Lwt_sequence.t * Lwt_tracing.thread_id * string option)

let create ?label () =
  (* Create a dummy thread to link all the task threads together. *)
  let trace_thread = Lwt.id_of_thread (fst (Lwt.wait ~thread_type:Lwt_tracing.Condition ())) in
  begin match label with
  | None -> ()
  | Some label -> Lwt_tracing.(!tracer.note_label) trace_thread label end;
  (Lwt_sequence.create (), trace_thread, label)

let wait ?mutex (cvar, trace_thread, label) =
  let waiter = Lwt.as_thread trace_thread (fun () -> Lwt.add_task_r cvar) in
  begin match label with
  | None -> ()
  | Some label -> Lwt_tracing.(!tracer.note_label) (Lwt.id_of_thread waiter) label end;
  let () =
    match mutex with
      | Some m -> Lwt_mutex.unlock m
      | None -> ()
  in
  Lwt.finalize
    (fun () -> waiter)
    (fun () ->
       match mutex with
         | Some m -> Lwt_mutex.lock m
         | None -> Lwt.return_unit)

let signal (cvar, trace_thread, _) arg =
  try
    Lwt.as_thread trace_thread (fun () -> Lwt.wakeup_later (Lwt_sequence.take_l cvar) arg)
  with Lwt_sequence.Empty ->
    ()

let broadcast (cvar, trace_thread, _) arg =
  let wakeners = Lwt_sequence.fold_r (fun x l -> x :: l) cvar [] in
  Lwt_sequence.iter_node_l Lwt_sequence.remove cvar;
  Lwt.as_thread trace_thread (fun () ->
    List.iter (fun wakener -> Lwt.wakeup_later wakener arg) wakeners
  )

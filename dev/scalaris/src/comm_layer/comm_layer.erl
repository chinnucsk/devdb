%  Copyright 2008 Konrad-Zuse-Zentrum fuer Informationstechnik Berlin
%
%   Licensed under the Apache License, Version 2.0 (the "License");
%   you may not use this file except in compliance with the License.
%   You may obtain a copy of the License at
%
%       http://www.apache.org/licenses/LICENSE-2.0
%
%   Unless required by applicable law or agreed to in writing, software
%   distributed under the License is distributed on an "AS IS" BASIS,
%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%   See the License for the specific language governing permissions and
%   limitations under the License.
%%%-------------------------------------------------------------------
%%% File    : comm_layer.erl
%%% Author  : Thorsten Schuett <schuett@zib.de>
%%% Description : Public interface to Communication Layer. 
%%%           Generic functions to send messages.
%%%           Distinguishes on runtime whether the destination is in the 
%%%           same Erlang virtual machine (use ! for sending) or on a remote
%%%           site (use comm_port:send()).
%%%
%%% Created :  04 Feb 2008 by Thorsten Schuett <schuett@zib.de>
%%%-------------------------------------------------------------------
%% @author Thorsten Schuett <schuett@zib.de>
%% @copyright 2008 Konrad-Zuse-Zentrum fuer Informationstechnik Berlin
%% @version $Id $
-module(comm_layer).

-author('schuett@zib.de').
-vsn('$Id: comm_layer.erl 953 2010-08-03 13:52:39Z kruber@zib.de $').

-export([start_link/0, send/2, this/0, here/1, is_valid/1]).

-include("scalaris.hrl").

%% @type process_id() = {inet:ip_address(), int(), pid()}.
-type(process_id() :: {inet:ip_address(), integer(), pid()}).

%%====================================================================
%% public functions
%%====================================================================

%% @doc starts the communication port (for supervisor)
-spec start_link() -> {ok, Pid::pid()} | ignore |
                      {error, Error::{already_started, Pid::pid()} | shutdown | term()}.
start_link() ->
    comm_port_sup:start_link().

%% @doc a process descriptor has to specify the erlang vm
%%      + the process inside. {IP address, port, pid}
%% @spec send(process_id(), term()) -> ok
-spec send(process_id(), term()) -> ok.
send({{_IP1, _IP2, _IP3, _IP4} = IP, Port, Pid} = Target, Message) ->
    {MyIP,MyPort} = comm_port:get_local_address_port(),
    %io:format("send: ~p:~p -> ~p:~p(~p) : ~p\n", [MyIP, MyPort, _IP, _Port, _Pid, Message]),
    IsLocal = (MyPort =:= Port) andalso (MyIP =:= IP),
    if
        IsLocal ->
            ?LOG_MESSAGE(Message, byte_size(term_to_binary(Message))),
            Pid ! Message,
            ok;
        true ->
            comm_port:send(Target, Message)
    end;

send(Target, Message) ->
    log:log(error,"[ CL ] wrong call to comm:send: ~w ! ~w", [Target, Message]),
    log:log(error,"[ CL ] stacktrace: ~w", [util:get_stacktrace()]),
    ok.

%% @doc returns process descriptor for the calling process
-spec(this/0 :: () -> process_id()).
this() ->
    here(self()).

-spec(here/1 :: (pid()) -> process_id()).
here(Pid) ->
    {LocalIP, LocalPort} = comm_port:get_local_address_port(),
    {LocalIP, LocalPort, Pid}.

is_valid({{_IP1, _IP2, _IP3, _IP4} = _IP, _Port, _Pid}) ->
    true;
is_valid(_) ->
    false.

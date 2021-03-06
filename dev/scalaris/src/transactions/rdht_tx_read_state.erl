%% @copyright 2009, 2010 onScale solutions GmbH

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

%% @author Florian Schintke <schintke@onscale.de>
%% @doc Part of replicated DHT implementation.
%%      The abstract datatype for the state for processing read operations.
%% @version $Id: rdht_tx_read_state.erl 906 2010-07-23 14:09:20Z schuett $
-module(rdht_tx_read_state).
-author('schintke@onscale.de').
-vsn('$Id: rdht_tx_read_state.erl 906 2010-07-23 14:09:20Z schuett $').

%-define(TRACE(X,Y), io:format(X,Y)).
-define(TRACE(X,Y), ok).

-export([new/1,new_val/3,new_client/3]).
-export([get_id/1,
         set_client/2, get_client/1,
         set_key/2, get_key/1,
         inc_numok/1, get_numok/1,
         get_numfailed/1,
         get_result/1, set_result/2,
         get_decided/1, set_decided/2,
         get_numreplied/1,
         is_client_informed/1,
         set_client_informed/1,
         add_reply/4,
         update_decided/2,
         is_newly_decided/1]).

%% {Id,
%% ClientPid/unknown,
%% Key,
%% NumOk,
%% NumFail,
%% Result = {Val, Vers},
%% is_decided
%% is_client_informed}

new(Id) ->
    {Id, unknown, unknown, 0, 0, {0, -1}, false, false}.
new_val(Id, Val, Vers) ->
    {Id, unknown, unknown, 0, 0, {Val, Vers}, false, false}.
new_client(Id, Pid, Key) ->
    {Id, Pid, Key, 0, 0, {0, -1}, false, false}.

get_id(State) ->             element(1, State).
set_client(State, Pid) ->    setelement(2, State, Pid).
get_client(State) ->         element(2, State).
set_key(State, Key) ->       setelement(3, State, Key).
get_key(State) ->            element(3, State).
inc_numok(State) ->          setelement(4, State, element(4, State) + 1).
get_numok(State) ->          element(4, State).
inc_numfailed(State) ->      setelement(5, State, element(5, State) + 1).
get_numfailed(State) ->      element(5, State).
get_result(State) ->         element(6, State).
set_result(State, Val) ->    setelement(6, State, Val).
get_decided(State) ->        element(7, State).
set_decided(State, Val) ->   setelement(7, State, Val).
is_client_informed(State) -> element(8, State).
set_client_informed(State) -> setelement(8, State, true).

get_numreplied(State) ->
    get_numok(State) + get_numfailed(State).

add_reply(State, Val, Vers, Maj) ->
    ?TRACE("rdht_tx_read_state:add_reply state val vers maj ~p ~p ~p ~p~n", [State, Val, Vers, Maj]),
   {OldVal, OldVers} = get_result(State),
    NewResult = case Vers > OldVers of
                    true -> {Val, Vers};
                    false -> {OldVal, OldVers}
                end,
    TmpState = set_result(State, NewResult),
    NewState = case Vers >= 0 of
                   true -> inc_numok(TmpState);
                   false -> inc_numfailed(TmpState)
               end,
    update_decided(NewState, Maj).

update_decided(State, Maj) ->
    ?TRACE("rdht_tx_read_state:update_decided state maj ~p ~p~n", [State, Maj]),
    NumOk = get_numok(State),
    NumFailed = get_numfailed(State),
    if (NumOk >= Maj) ->
            set_decided(State, value);
       (NumFailed >= Maj) ->
            set_decided(State, not_found);
       true -> State
    end.

is_newly_decided(State) ->
    ?TRACE("rdht_tx_read_state:is_newly_decided State ~p ~n", [State]),
    (false =/= get_decided(State))
        andalso (not is_client_informed(State)).

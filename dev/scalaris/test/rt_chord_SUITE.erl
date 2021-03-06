% @copyright 2010 Konrad-Zuse-Zentrum fuer Informationstechnik Berlin

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

%%% @author Nico Kruber <kruber@zib.de>
%%% @doc    Unit tests for src/rt_chord.erl.
%%% @end
%% @version $Id: rt_chord_SUITE.erl 960 2010-08-03 13:53:39Z kruber@zib.de $
-module(rt_chord_SUITE).
-author('kruber@zib.de').
-vsn('$Id: rt_chord_SUITE.erl 960 2010-08-03 13:53:39Z kruber@zib.de $').

-compile(export_all).

-include("unittest.hrl").
-include("scalaris.hrl").

all() ->
    [next_hop].

suite() ->
    [
     {timetrap, {seconds, 10}}
    ].

init_per_suite(Config) ->
    file:set_cwd("../bin"),
    error_logger:tty(true),
    Owner = self(),
    Pid = spawn(fun () ->
                        crypto:start(),
                        process_dictionary:start_link(),
                        config:start_link(["scalaris.cfg", "scalaris.local.cfg"]),
                        comm_port:start_link(),
                        timer:sleep(1000),
                        comm_port:set_local_address({127,0,0,1},14195),
                        application:start(log4erl),
                        Owner ! {continue},
                        receive
                            {done} -> ok
                        end
                end),
    receive
        {continue} -> ok
    end,
    [{wrapper_pid, Pid} | Config].

end_per_suite(Config) ->
    {value, {wrapper_pid, Pid}} = lists:keysearch(wrapper_pid, 1, Config),
    gen_component:kill(process_dictionary),
    error_logger:tty(false),
    exit(Pid, kill),
    Config.

next_hop(_Config) ->
    erlang:put(instance_id, "rt_chord_SUITE_group"),
    MyNode = node:new(fake_dht_node(), 0, 0),
    Succ = node:new(fake_dht_node(), 1, 0),
    Pred = node:new(fake_dht_node(), 1000000, 0),
    DHTNodes = [fake_dht_node() || _ <- lists:seq(1, 6)],
    RT = gb_trees:from_orddict([{1, Succ},
                                {2, node:new(lists:nth(1, DHTNodes), 2, 0)},
                                {4, node:new(lists:nth(2, DHTNodes), 4, 0)},
                                {8, node:new(lists:nth(3, DHTNodes), 8, 0)},
                                {16, node:new(lists:nth(4, DHTNodes), 16, 0)},
                                {32, node:new(lists:nth(5, DHTNodes), 32, 0)},
                                {64, node:new(lists:nth(6, DHTNodes), 64, 0)}]),
    % note: dht_node_state:new/3 will call process_dictionary:get_group_member(paxos_proposer)
    % which will fail here -> however, we don't need this process
    State = dht_node_state:new(RT, nodelist:new_neighborhood(Pred, MyNode, Succ), ?DB:new(node:id(MyNode))),
    ?equals(rt_chord:next_hop(State, 0), lists:nth(6, DHTNodes)),
    ?equals(rt_chord:next_hop(State, 1), node:pidX(Succ)), % succ is responsible
    ?equals(rt_chord:next_hop(State, 2), node:pidX(Succ)),
    ?equals(rt_chord:next_hop(State, 3), lists:nth(1, DHTNodes)),
    ?equals(rt_chord:next_hop(State, 7), lists:nth(2, DHTNodes)),
    ?equals(rt_chord:next_hop(State, 9), lists:nth(3, DHTNodes)),
    ?equals(rt_chord:next_hop(State, 31), lists:nth(4, DHTNodes)),
    ?equals(rt_chord:next_hop(State, 64), lists:nth(5, DHTNodes)),
    ?equals(rt_chord:next_hop(State, 65), lists:nth(6, DHTNodes)),
    ?equals(rt_chord:next_hop(State, 1000), lists:nth(6, DHTNodes)),
    
    [exit(Node, kill) || Node <- DHTNodes],
    exit(node:pidX(MyNode), kill),
    exit(node:pidX(Succ), kill),
    exit(node:pidX(Pred), kill),
    ok.

%% helpers

fake_dht_node() ->
    DHT_Node = spawn(?MODULE, fake_dht_node_start, [self()]),
    receive
        {started, DHT_Node} -> DHT_Node
    end.

fake_dht_node_start(Supervisor) ->
%%     process_dictionary:register_process("rt_chord_SUITE_group", dht_node, self()),
    Supervisor ! {started, self()},
    fake_process().

fake_process() ->
    timer:sleep(1000),
    fake_process().

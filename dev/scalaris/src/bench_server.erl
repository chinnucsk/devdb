%  Copyright 2007-2008, 2010 Konrad-Zuse-Zentrum fuer Informationstechnik Berlin
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
%%%-----------------------------------------------------------------------------
%%% File    : bench_server.erl
%%% Author  : Thorsten Schuett <schuett@zib.de>
%%% Description : bench server
%%%
%%% Created :  13 Oct 2008 by Thorsten Schuett <schuett@zib.de>
%%%-----------------------------------------------------------------------------
%% @author Thorsten Schuett <schuett@zib.de>
%% @copyright 2007-2008 Konrad-Zuse-Zentrum fuer Informationstechnik Berlin
%% @doc This is a small server for running benchmarks
%% @version $Id: bench_server.erl 911 2010-07-26 15:04:46Z kruber@zib.de $
-module(bench_server).

-author('schuett@zib.de').
-vsn('$Id: bench_server.erl 911 2010-07-26 15:04:46Z kruber@zib.de $').

-export([start_link/0, start/0]).
-export([run_increment/2, run_increment_v2/2, run_increment/3, run_increment_locally/2]).
-export([run_read/2, run_read_v2/2, run_read/3, bench_runner/3]).

-include("scalaris.hrl").

%%==============================================================================
%% public interface
%%==============================================================================
%% @doc run an increment benchmark (i++) on all nodes
run_increment(ThreadsPerVM, Iterations) ->
    Msg = {bench_increment, ThreadsPerVM, Iterations, comm:this()},
    runner(ThreadsPerVM, Iterations, [verbose], Msg).

run_increment_v2(ThreadsPerVM, Iterations) ->
    Msg = {bench_increment_v2, ThreadsPerVM, Iterations, comm:this()},
    runner(ThreadsPerVM, Iterations, [verbose], Msg).

run_increment_locally(ThreadsPerVM, Iterations) ->
    Msg = {bench_increment, ThreadsPerVM, Iterations, comm:this()},
    runner(ThreadsPerVM, Iterations, [locally, verbose], Msg).

%% @doc run an increment benchmark (i++) on all nodes
%% profile : enable profiling
%% {copies, Copies}: run in the benchmark in Copies nodes
run_increment(ThreadsPerVM, Iterations, Options) ->
    Msg = {bench_increment, ThreadsPerVM, Iterations, comm:this()},
    runner(ThreadsPerVM, Iterations, Options, Msg).

%% @doc run an read benchmark on all nodes
run_read(ThreadsPerVM, Iterations) ->
    Msg = {bench_read, ThreadsPerVM, Iterations, comm:this()},
    runner(ThreadsPerVM, Iterations, [verbose], Msg).

run_read_v2(ThreadsPerVM, Iterations) ->
    Msg = {bench_read_v2, ThreadsPerVM, Iterations, comm:this()},
    runner(ThreadsPerVM, Iterations, [verbose], Msg).

run_read(ThreadsPerVM, Iterations, Options) ->
    Msg = {bench_read, ThreadsPerVM, Iterations, comm:this()},
    runner(ThreadsPerVM, Iterations, Options, Msg).

runner(ThreadsPerVM, Iterations, Options, Message) ->
    ServerList = case lists:member(locally, Options) of
                     true ->
                         [comm:make_global(bench_server)];
                     false ->
                         case lists:keysearch(copies, 1, Options) of
                             {value, {copies, Copies}} ->
                                 lists:sublist(util:get_nodes(), Copies);
                             false ->
                                 util:get_nodes()
                         end
                 end,
    %io:format("~p~n", [ServerList]),
    {BeforeDump, _} = admin:get_dump(),
    Before = erlang:now(),
    Times = case lists:member(profile, Options) of
                false ->
                    [comm:send(Server, Message) || Server <- ServerList],
                    [receive {done, Time} -> io:format("BS: ~p~n",[Time]),Time end || _Server <- ServerList];
                true ->
                    Result = fprof:apply(fun () ->
                                                 [comm:send(Server, Message) || Server <- ServerList],
                                                 [receive {done, Time} -> Time end || _Server <- ServerList]
                                         end,
                                         [], [{procs, process_dictionary:get_all_pids()}]),
                    fprof:profile(),
                    %fprof:analyse(),
                    fprof:analyse([{cols, 140}, details, callers, totals, {dest, []}]), 
                    Result
            end,
    After = erlang:now(),
    case lists:member(verbose, Options) of
        true ->
            {AfterDump, _} = admin:get_dump(),
            RunTime = timer:now_diff(After, Before),
            DiffDump = admin:diff_dump(BeforeDump, AfterDump, RunTime),
            io:format("servers: ~p threads/vm: ~p iterations: ~p~n",
                      [length(ServerList), ThreadsPerVM, Iterations]),
            io:format("total time: ~p~n", [RunTime / 1000000.0]),
            io:format("1/s: ~p~n",
                      [length(ServerList) * ThreadsPerVM * Iterations / RunTime * 1000000.0]),
            Throughput = [ThreadsPerVM * Iterations / Time * 1000000.0 || Time <- Times],
            io:format("~p~n", [Throughput]),
            io:format("High load avg. latency: ~p ms~n", [ RunTime / 1000.0 / Iterations ]),
            io:format("Message statistics (message name, bytes, how often): ~p~n", [DiffDump]);
        false ->
            ok
    end,
    ok.

%%==============================================================================
%% benchmarks
%%==============================================================================
%% @doc run the increment bench locally
-spec(bench_increment/3 :: (integer(), integer(), any()) -> ok).
bench_increment(Threads, Iterations, Owner) ->
    Bench = fun (Parent) -> 
	          Key = get_and_init_key(),
		  bench_increment:process(Parent, 
			                  Key, 
                                          Iterations) 
	  end,
    {Time, _} = timer:tc(?MODULE, bench_runner, [Threads, Iterations, Bench]),
    comm:send(Owner, {done, Time}),
    ok.

bench_increment_v2(Threads, Iterations, Owner) ->
    Bench = fun (Parent) -> 
	          Key = get_and_init_key(),
		  bench_increment:process_v2(Parent, 
                                             Key, 
                                             Iterations) 
	  end,
    {Time, _} = timer:tc(?MODULE, bench_runner, [Threads, Iterations, Bench]),
    comm:send(Owner, {done, Time}),
    ok.

%% @doc run the read bench locally
-spec(bench_read/3 :: (integer(), integer(), any()) -> ok).
bench_read(Threads, Iterations, Owner) ->
    Bench = fun (Parent) -> 
	          Key = get_and_init_key(),
		  run_bench_read(Parent, 
			     Key, 
		             Iterations)
	  end,
    {Time, _} = timer:tc(?MODULE, bench_runner, [Threads, Iterations, Bench]),
    comm:send(Owner, {done, Time}),
    ok.

bench_read_v2(Threads, Iterations, Owner) ->
    Bench = fun (Parent) -> 
	          Key = get_and_init_key(),
		  run_bench_read_v2(Parent,
                                    Key,
                                    Iterations, 0)
	  end,
    {Time, _} = util:tc(?MODULE, bench_runner, [Threads, Iterations, Bench]),
    comm:send(Owner, {done, Time}),
    ok.

-spec(bench_runner/3 :: (integer(), integer(), any()) -> ok).
bench_runner(0, _Iterations, _Bench) ->
    ok;
bench_runner(Threads, Iterations, Bench) ->
    Self = self(),
    spawn(fun () ->
	Bench(Self)
    end),
    bench_runner(Threads - 1, Iterations, Bench),
    receive
	{done, _} ->
	    ok
    end.

run_bench_read(Owner, _Key, 0) ->
    comm:send_local(Owner , {done, ok});
run_bench_read(Owner, Key, Iterations) ->
    case transaction_api:quorum_read(Key) of
	{fail, _Reason} ->
	    run_bench_read(Owner, Key, Iterations);
	{_Value, _Version} ->
	    run_bench_read(Owner, Key, Iterations - 1)
    end.

run_bench_read_v2(Owner, _Key, 0, Fail) ->
    io:format("repeated requests: ~p~n", [Fail]),
    comm:send_local(Owner , {done, ok});
run_bench_read_v2(Owner, Key, Iterations, Fail) ->
    case cs_api_v2:read(Key) of
	{fail, _Reason} ->
	    run_bench_read_v2(Owner, Key, Iterations, Fail + 1);
	_Value ->
	    run_bench_read_v2(Owner, Key, Iterations - 1, Fail)
    end.

%%==============================================================================
%% main loop
%%==============================================================================
loop() ->
    receive
	{bench_increment, Threads, Iterations, Owner} ->
	    spawn(fun () -> 
			  bench_increment(Threads, Iterations, Owner) 
		  end),
	    loop();
	{bench_increment_v2, Threads, Iterations, Owner} ->
	    spawn(fun () -> 
			  bench_increment_v2(Threads, Iterations, Owner) 
		  end),
	    loop();
	{bench_read, Threads, Iterations, Owner} ->
	    spawn(fun () -> 
			  bench_read(Threads, Iterations, Owner) 
		  end),
	    loop();
	{bench_read_v2, Threads, Iterations, Owner} ->
	    spawn(fun () -> 
			  bench_read_v2(Threads, Iterations, Owner) 
		  end),
	    loop()
    end.
%%==============================================================================
%% startup functions
%%==============================================================================
start() ->
    register(bench_server, self()),
    loop().

%% @doc spawns a bench_server
-spec(start_link/0 :: () -> {ok, pid()}).
start_link() ->
    {ok, spawn_link(?MODULE, start, [])}.

%%==============================================================================
%% helper functions
%%==============================================================================
get_and_init_key() ->
    Key = ?RT:get_random_node_id(),
    case transaction_api:single_write(Key, 0) of
      commit ->
        Key;
      {fail, abort} ->
	    io:format("geT_and_init_key 1 failed, retrying~n", []),
        get_and_init_key();
      {fail, timeout} ->
	    io:format("geT_and_init_key 2 timeout, retrying~n", []),
        get_and_init_key()
    end.


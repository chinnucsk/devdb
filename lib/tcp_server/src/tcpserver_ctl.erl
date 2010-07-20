-module(tcpserver_ctl).
% remote control of the server

-export([get_config_file/0, get_log_file/0]).
-export([start/0, process/1]).

-define(DEFAULT_CONFIG_FILE, "tcpserver.cfg").
-define(DEFAULT_LOG_FILE, "tcpserver.log").
-define(STATUS_SUCCESS, 0).
-define(STATUS_ERROR,   1).
-define(STATUS_USAGE,   2).
-define(STATUS_BADRPC,  3).

get_config_file() ->
    case os:getenv("MYAPP_CONFIG_PATH") of
	false ->
	    ?DEFAULT_CONFIG_FILE;
	Path ->
	    Path
    end.

get_log_file() ->
    case os:getenv("MYAPP_LOG_PATH") of
	false ->
	    ?DEFAULT_LOG_FILE;
	Path ->
	    Path
    end.

start() ->
    case init:get_plain_arguments() of
	[SNode | Args] ->
	    Node = list_to_atom(SNode),
	    Status = case rpc:call(Node, ?MODULE, process, [Args]) of
			 {badrpc, Reason} ->
			     io:format("RPC failed on the node ~p: ~p~n", [Node, Reason]),
			     ?STATUS_BADRPC;
			 S ->
			     S
		     end,
	    halt(Status);
	_ ->
	    print_usage(),
	    halt(?STATUS_USAGE)
    end.

process(["status"]) ->
    {InternalStatus, ProvidedStatus} = init:get_status(),
    io:format("Node ~p is ~p. Status: ~p~n",
              [node(), InternalStatus, ProvidedStatus]),
    case lists:keysearch(tcp_server, 1, application:which_applications()) of
        false ->
            io:format("tcp_server is not running~n", []),
            ?STATUS_ERROR;
        {value,_Version} ->
            io:format("tcp_server is running~n", []),
            ?STATUS_SUCCESS
    end;

process(["stop"]) ->
    init:stop(),
    ?STATUS_SUCCESS;

process(["restart"]) ->
    init:restart(),
    ?STATUS_SUCCESS;

process(_) ->
    print_usage(),
    ?STATUS_ERROR.


print_usage() ->
    io:format(
      "Usage: tcpserverctl command~n"
      "~n"
      "Available commands:~n"
      "  start~n"
      "  stop~n"
      "  restart~n"
      "  status~n"
      "  debug~n"
      "~n"
      "Example:~n"
      "  tcpserverctl restart~n"
     ).
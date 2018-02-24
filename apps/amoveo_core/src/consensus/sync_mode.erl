-module(sync_mode).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
	quick/0, normal/0, check/0]).
init(ok) -> 
    {ok, Kind} = application:get_env(amoveo_core, kind),
    case Kind of
	"production" ->
	    spawn(fun() ->
			  timer:sleep(2000),
			  sync:start()
		  end),
	    spawn(fun() ->
			  timer:sleep(20000),
			  check_switch_to_normal()
		  end);
	_ -> ok
    end,
    {ok, quick}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast(_, X) -> {noreply, X}.
handle_call(quick, _From, _) -> 
    {reply, quick, quick};
handle_call(normal, _From, _) -> 
    {reply, normal, normal};
handle_call(_, _From, X) -> {reply, X, X}.

quick() ->
    gen_server:call(?MODULE, quick).
normal() ->
    gen_server:call(?MODULE, normal).
check() ->
    gen_server:call(?MODULE, check).

check_switch_to_normal() ->
    T1 = block_absorber:check(),
    T = timer:now_diff(now(), T1),
    S = T / 1000000,%seconds
    if
	S > 60 -> sync_mode:normal();
	true -> 
	    sync:start(),
	    timer:sleep(15000),
	    check_switch_to_normal()
    end.
	    
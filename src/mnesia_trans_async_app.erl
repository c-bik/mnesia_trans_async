-module(mnesia_trans_async_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    mnesia_trans_async_sup:start_link().

stop(_State) ->
    ok.

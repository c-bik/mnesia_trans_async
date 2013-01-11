-module(mnesia_trans_async).

%% Application callbacks
-compile(export_all).

%% ===================================================================
%% Application callbacks
%% ===================================================================

setup() ->
    {atomic, ok} = mnesia:create_table(table, [{attributes, [col1, col2, col3]}]),
    ok.

-define(ROWCOUNT, 100).
-define(THREAD_A_DELAY, 2000).
-define(THREAD_B_DELAY, 2000).
-define(THREAD_A_CHUNK, 10).
-define(THREAD_B_CHUNK, 20).

run_test() ->
    mnesia:stop(),
    mnesia:start(),
    setup(),
    async_insert(),
    timer:sleep(?THREAD_A_DELAY),
    recv_async("_A_", ?THREAD_A_CHUNK, ?THREAD_A_DELAY),
    recv_async("_B_", ?THREAD_B_CHUNK, ?THREAD_B_DELAY),
    TotalDelay = round(?ROWCOUNT / ?THREAD_A_CHUNK * ?THREAD_A_DELAY + ?ROWCOUNT / ?THREAD_B_CHUNK * ?THREAD_B_DELAY),
    io:format("waiting... ~p~n", [TotalDelay]),
    timer:sleep(TotalDelay).

async_insert() ->
    F = fun
            (_, 0) -> ok;
            (F, R) ->
                mnesia:transaction(fun() ->
                    mnesia:write({table, R, R+1, R+2})
                end),
                timer:sleep(?THREAD_B_DELAY div 20),
                F(F,R-1)
    end,
    spawn(fun() -> F(F, ?ROWCOUNT) end).

recv_async(Title, Limit, Delay) ->
    F0 = fun() ->
        Pid = start_trans(self(), Limit),
        F = fun(F) ->
            Pid ! next,
            receive
                eot ->
                    io:format("[~p] finished~n", [Title]);
                {row, Row} ->
                    io:format("[~p] got rows ~p~n", [Title, length(Row)]),
                    timer:sleep(Delay),
                    F(F)
            end
        end,
        F(F)
    end,
    spawn(F0).

start_trans(Pid, Limit) ->
    F =
    fun(F,Contd0) ->
        receive
            abort ->
                io:format("Abort~n", []);
            next ->
                case (case Contd0 of
                      undefined -> mnesia:select(table, [{'$1', [], ['$_']}], Limit, read);
                      Contd0 -> mnesia:select(Contd0)
                      end) of
                {Rows, Contd1} ->
                    Pid ! {row, Rows},
                    F(F,Contd1);
                '$end_of_table' -> Pid ! eot
                end
        end
    end,
    spawn(mnesia, transaction, [F, [F,undefined]]).

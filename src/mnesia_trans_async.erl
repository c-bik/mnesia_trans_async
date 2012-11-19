-module(mnesia_trans_async).

%% Application callbacks
-compile(export_all).

%% ===================================================================
%% Application callbacks
%% ===================================================================

setup(RowCount) ->
    {atomic, ok} = mnesia:create_table(table, [{attributes, [col1, col2, col3]}]),
    _ = [mnesia:dirty_write({table, R, R+1, R+2}) || R <- lists:seq(1,RowCount)],
    ok.

-define(ROWCOUNT, 100).
-define(THREAD_A_DELAY, 100).
-define(THREAD_B_DELAY, 200).
-define(THREAD_A_CHUNK, 10).
-define(THREAD_B_CHUNK, 20).

run_test() ->
    mnesia:stop(),
    mnesia:start(),
    setup(?ROWCOUNT),
    recv_async("_A_", ?THREAD_A_CHUNK, ?THREAD_A_DELAY),
    recv_async("_B_", ?THREAD_B_CHUNK, ?THREAD_B_DELAY),
    TotalDelay = round(?ROWCOUNT / ?THREAD_A_CHUNK * ?THREAD_A_DELAY + ?ROWCOUNT / ?THREAD_B_CHUNK * ?THREAD_B_DELAY),
    io:format("waiting... ~p~n", [TotalDelay]),
    timer:sleep(TotalDelay).

recv_async(Title, Limit, Delay) ->
    F0 = fun() ->
        Pid = start_trans(self(), Limit),
        F = fun(F) ->
            Pid ! next,
            receive
                eot ->
                    io:format("finished~n", []);
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

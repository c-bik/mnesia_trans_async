-module(mnesia_trans_async).

%% Application callbacks
-compile(export_all).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start() -> application:start(mnesia_trans_async).

stop()  -> application:stop(mnesia_trans_async).

setup(RowCount) ->
    {atomic, ok} = mnesia:create_table(table, [{attributes, [col1, col2, col3]}]),
    _ = [mnesia:dirty_write({table, R, R+1, R+2}) || R <- lists:seq(1,RowCount)],
    ok.

recv_async(Limit, Delay) ->
    F0 = fun() ->
        Pid = start_trans(self(), Limit),
        F = fun(F) ->
            Pid ! next,
            receive
                eot ->
                    io:format("finished~n", []);
                {row, Row} ->
                    io:format("got rows ~p~n", [Row]),
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

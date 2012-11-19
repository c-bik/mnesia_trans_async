Asnychronous Access to Mnesia Transaction
=========================================

Motivation
----------

mnesia:transaction/x in all its form accepts a function and returns
only after its execution if compele or it is aborted. This is not very
convelient for reading a long table with select/4 and select/1 combination.
Specially if it is needed to access intermediate NObjects rows produce.

So here is a demo about how it can be achieved.
----------

### Try the demo
<code>
1> mnesia_trans_async:run_test()<br>
</code>

### Sample Output
<code>
mnesia_trans_async:run_test().<br>
waiting... 2000<br>
["_A_"] got rows 10<br>
["_B_"] got rows 20<br>
["_A_"] got rows 10<br>
["_B_"] got rows 20<br>
["_A_"] got rows 10<br>
["_A_"] got rows 10<br>
["_B_"] got rows 20<br>
["_A_"] got rows 10<br>
["_A_"] got rows 10<br>
["_B_"] got rows 20<br>
["_A_"] got rows 10<br>
["_A_"] got rows 10<br>
["_B_"] got rows 20<br>
["_A_"] got rows 10<br>
["_A_"] got rows 10<br>
finished<br>
finished
</code>

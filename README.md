Asnychronous Access to Mnesia Transaction
=========================================

Motivation
----------

mnesia:transaction/x in all its form accepts a function and returns
only after its execution is compele or its is aborted. This is not very
convelient for reading a long table with select/4 and select/1 combination.
Specially if it is needed to access intermediate NObjects rows produce.

So here is a demo about how it can be achieved.
----------

### Try the demo
<code>
1> mnesia_trans_async:start()<br>
1> mnesia_trans_async:setup(10) % Number of rows to insert in the sample table<br>
1> mnesia_trans_async:recv_async(2, 100) % Number of rows for each block, Delay between fetching two blocks<br>
</code>

### Sample Output
<code>
2> mnesia_trans_async:setup(10).<br>
ok<br>
3> mnesia_trans_async:recv_async(2, 100).<br>
got rows [{table,3,4,5},{table,5,6,7}]<br>
got rows [{table,8,9,10},{table,2,3,4}]<br>
got rows [{table,9,10,11},{table,10,11,12}]<br>
got rows [{table,4,5,6},{table,1,2,3}]<br>
got rows [{table,7,8,9},{table,6,7,8}]<br>
finished
</code>
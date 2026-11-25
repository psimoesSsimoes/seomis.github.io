---
title: 'Reading a `pt-query-digest` Report Without Losing Your Mind'
date: 2025-05-02 00:00:00
featured_image: ''
excerpt: A quick guide to decoding pt-query-digest reports and fixing slow MySQL queries.
---

Ever run `pt-query-digest` on a MySQL slow log and been handed a wall of text, with no idea where to start? In this post I'll walk through how I read that report: what I pay attention to, and what I ignore.

## The scenario

Picture an online shop running on a single MySQL server. Three application servers, `10.0.1.12` to `10.0.1.14`, serve the shop and its back office, and a fourth host, `10.0.2.5`, runs scheduled jobs. For a couple of weeks the database has felt slow, nobody can say which part of it, and you've been handed two weeks of slow log, captured with `long_query_time` set to one second. Running `pt-query-digest` over it gives a 764-line report, and you only need about 50 of those lines, read in the right order.

<aside class="note" aria-label="Note" markdown="1">
I made up the shop and generated its slow log, so that the numbers add up. Everything else is real: the report is pt-query-digest 3.7.1 output, and the `EXPLAIN` plans come from MySQL 8.0.46.

In the report excerpts, coloured lines are my annotations and greyed lines are the ones I skip.
</aside>

## How the report is laid out

The report comes in three parts, and you read each one differently:

<div class="language-text highlighter-rouge"><div class="highlight"><pre class="highlight"><code> slow.log --&gt; pt-query-digest --&gt; report.txt  (764 lines for this log)

 +----------------------------------------------------------------------+
 | SUMMARY                                         <span class="k">1  glance</span>            |
 | 9 lines, once. Totals for the whole log: how many queries,           |
 | over which days, how much time.                                      |
 +----------------------------------------------------------------------+
 | PROFILE                                         <span class="k">2  decide here</span>       |
 | One line per query shape, most total time first.                     |
 |                                                                      |
 |   Rank  Query ID      Response time                                  |
 |      1  0xAE91...     41.1%  ------------------+                     |
 |      2  0x46BD...     15.0%  ----------------+ |                     |
 |      3  0x690B...     10.2%                  | |                     |
 +----------------------------------------------|-|---------------------+
 | QUERY BLOCKS                                 | | <span class="k">3  open only the</span>    |
 | About 30 lines per query, in profile         | | <span class="k">   ones you chose</span>   |
 | order, matched to it by Query ID.            | |                     |
 |                                              | |                     |
 |   Query 1: ... ID 0xAE91...  &lt;---------------|-+                     |
 |   Query 2: ... ID 0x46BD...  &lt;---------------+                       |
 |   ... 20 more                                                        |
 +----------------------------------------------------------------------+
</code></pre></div></div>

I read it by asking five questions, in this order:

| | Question | Where the answer is |
|---|---|---|
| 1 | Is this the right log? | The summary |
| 2 | Which queries matter? | The profile |
| 3 | What kind of slow is each one? | The query blocks |
| 4 | Why is it slow? | `EXPLAIN`, run yourself |
| 5 | Is it worth fixing? | Not in the report |

The rest of this post takes them one at a time.

## The summary: is this the right log?

The summary opens the report, and a glance is enough to confirm you're looking at the right log over the right days.

<div class="language-text highlighter-rouge"><div class="highlight"><pre class="highlight"><code># Overall: <span class="nf">1.62k total, 161 unique</span>, <span class="nf">0.00 QPS</span>, 0.02x concurrency __________
<span class="k">           ^^^^^^^^^^^^^^^^^^^^^^^  ^^^^^^^^</span>
<span class="k">           |                        +- slow queries logged per second, not traffic</span>
<span class="k">           +- 1,620 slow queries, but only 161 distinct shapes to look at</span>
# Time range: <span class="nf">2025-04-17T00:08:44 to 2025-04-30T23:23:54</span>
<span class="k">              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^</span>
<span class="k">              14 days. Is it the period I meant to look at?</span>
# Attribute          total     min     max     avg     95%  stddev  median
# ============     ======= ======= ======= ======= ======= ======= =======
# Exec time         <span class="nf">28756s</span>      <span class="nf">1s</span>    621s     <span class="nf">18s</span>     45s     42s      <span class="nf">9s</span>
<span class="k">                    ^^^^^^      ^^             ^^^                      ^^</span>
<span class="k">                    |           |              +- avg is twice the median (9s)</span>
<span class="k">                    |           +- nothing under 1s: that is long_query_time</span>
<span class="k">                    +- the 100% behind every "share of time" further down</span>
# Lock time          <span class="nf">2596s</span>    50us     48s      2s     12s      5s   214us
<span class="k">                     ^^^^^ 9% of all exec time is spent waiting for locks</span>
# Rows sent        646.39k       0   1.17k  408.59   1.14k  430.15  223.14
# Rows examine       <span class="nf">3.09G</span>       1  46.19M   1.95M   4.93M   4.17M 619.64k
<span class="k">                     ^^^^^ 3.09G rows read to send 646.39k back: about 5,000 to 1</span>
<span class="c"># Query size       118.81k      38     141   75.10  130.47   18.70   72.65</span>
</code></pre></div></div>

One number here is easy to misread. The `1s` minimum isn't your fastest query; it's your `long_query_time`. Anything quicker never reached the log, so a 200ms query running a million times a day doesn't appear at all, however much it costs you.

The suffixes are powers of 1024, too: the `5.09M` rows you'll see later are 5,340,000.

## The profile: which queries matter?

The profile is where you decide what to work on.

<div class="language-text highlighter-rouge"><div class="highlight"><pre class="highlight"><code># Profile
# Rank Query ID                            Response time    Calls R/Call  
# ==== =================================== ================ ===== ========
<span class="k">       ID: search the report for it           total   share  runs  seconds  V/M  verb + table</span>
<span class="k">       to reach the query's block            seconds  of all       per run</span>
#    1 0xAE91765F93CB7AE2A0EE9F055896F443  11825.9490 <span class="nf">41.1%</span>   <span class="nf">381</span>  <span class="nf">31.0392</span> 12.73 SELECT users
<span class="k">  top share, ~27 runs a day, 31s each: open this one  ^^^^^   ^^^  ^^^^^^^</span>
#    2 0x46BD873C3879537B0AFEF6591327F94B   4306.4520 15.0%    <span class="nf">11</span> <span class="nf">391.4956</span>  <span class="nf">0.40</span> SELECT orders
<span class="k">           rare, very slow, steady (low V/M): looks scheduled  ^^ ^^^^^^^^  ^^^^</span>
#    3 0x690B1010071C0B026AEF4F36F049F76D   2926.1246 10.2%   212  <span class="nf">13.8025</span>  4.96 <span class="nf">UPDATE carts</span>
<span class="k">                   an UPDATE averaging 13.8s: check its Lock time  ^^^^^^^       ^^^^^^^^^^^^</span>
#    4 0x3830162E023FB197F4EC905913D986E3   2016.5031  7.0%    96  21.0052  2.35 SELECT orders
#    5 0x2BDD44DA2721F676B50ABF469FDE6EFC   1806.0882  6.3%     3 602.0294  0.29 DELETE sessions
#    6 0xD94BB68D01BFF37827DE59F2D15027A8   1228.2025  4.3%   140   8.7729  1.34 SELECT products
<span class="k">       ... 16 more rows cut ...</span>
# MISC 0xMISC                               2869.0380 <span class="nf">10.0%</span>   466   6.1567   0.0 <span class="nf">&lt;139 ITEMS&gt;</span>
<span class="k">           139 other query shapes share the last 10%  ^^^^^                      ^^^^^^^^^^^</span>
</code></pre></div></div>

The last two columns have no header. The first is V/M, which measures how erratic a query's timing is, and the second names the statement and its table.

It's natural to start at the top and work down, but the profile ranks by total time, and total time is not the same as harm. Compare the first two rows:

| | Rank 1, `SELECT users` | Rank 2, `SELECT orders` |
|---|---|---|
| Share of logged time | 41.1% | 15.0% |
| Runs in 14 days | 381 | 11 |
| Time per run | 8s to 160s | 366s to 415s |
| Hosts, from its block | three | one |

Rank 2 runs rarely, takes about the same time on every run, and always comes from `10.0.2.5`, the host that runs scheduled jobs. Is six and a half minutes too long for a scheduled job? The report can't say. Nobody may be waiting for it, or someone may have accepted the slowness as a deliberate tradeoff, so I'd ask before touching it.

Rank 1 is different. It runs all day from the application hosts, half a minute at a time, and something waits on every run. That's the one I open.

## The query block: what kind of slow is it?

Further down the report, the same ID heads the query's own block. Most of the story is in the two `Rows` lines:

<div class="language-text highlighter-rouge"><div class="highlight"><pre class="highlight"><code># Query 1: <span class="nf">0.00 QPS</span>, 0.01x concurrency, <span class="nf">ID 0xAE91765F93CB7AE2A0EE9F055896F443</span> <span class="nf">at byte 277187</span>
<span class="k">           ^^^^^^^^                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^</span>
<span class="k">           |                            |   slowest run's offset in slow.log -+</span>
<span class="k">           |                            +- the ID from the profile row</span>
<span class="k">           +- 381 calls in 14 days rounds to zero per second</span>
<span class="c"># This item is included in the report because it matches --limit.</span>
# Scores: <span class="nf">V/M = 12.73</span>
<span class="k">          ^^^^^^^^^^^ variance-to-mean of exec time: runs differ a lot</span>
<span class="c"># Time range: 2025-04-17T03:31:26 to 2025-04-30T19:38:23</span>
# Attribute    pct   total     min     max     avg     95%  stddev  median
# ============ === ======= ======= ======= ======= ======= ======= =======
# Count         <span class="nf">23</span>     381
<span class="k">                ^^ pct column: 23% of the logged queries...</span>
# Exec time     <span class="nf">41</span>  11826s      <span class="nf">8s</span>    160s     31s     69s     20s     25s
<span class="k">                ^^              ^^</span>
<span class="k">                |               +- the best run still took 8s: it is never fast</span>
<span class="k">                +- ...41% of the time</span>
# Lock time      0    <span class="nf">66ms</span>    50us   299us   173us   287us    73us   176us
<span class="k">                      ^^^^ 66ms of lock waiting in 381 runs: not a lock problem</span>
# Rows sent     67 435.35k   1.12k   1.17k   <span class="nf">1.14k</span>   1.14k      25   1.09k
<span class="k">         about 1,170 rows come back per run  ^^^^^</span>
# Rows examine  <span class="nf">61</span>   1.89G   <span class="nf">5.09M   5.09M   5.09M</span>   5.09M       0   5.09M
<span class="k">                ^^           ^^^^^^^^^^^^^^^^^^^^^</span>
<span class="k">                |            +- min = max = avg: the same 5.09M rows every run</span>
<span class="k">                +- ...and 61% of all rows read</span>
<span class="c"># Query size    23  27.91k      75      75      75      75       0      75</span>
<span class="c"># String:</span>
<span class="c"># Databases    shop</span>
<span class="c"># Hosts        10.0.1.12 (135/35%), 10.0.1.14 (124/32%)... 1 more</span>
<span class="c"># Users        app</span>
# Query_time distribution
<span class="c">#   1us</span>
<span class="c">#  10us</span>
<span class="c"># 100us</span>
<span class="c">#   1ms</span>
<span class="c">#  10ms</span>
<span class="c"># 100ms</span>
#    1s  ###
#  10s+  ################################################################
<span class="k">         ^ nearly every run takes longer than 10s</span>
# Tables
#    SHOW TABLE STATUS FROM `shop` LIKE 'users'\G
#    SHOW CREATE TABLE `shop`.`users`\G
<span class="k">     ^ run these two for the table's size and its indexes</span>
# EXPLAIN /*!50100 PARTITIONS*/
SELECT * FROM users WHERE last_login &lt; '2025-01-15' AND status = 'inactive'\G
<span class="k">^ the slowest run, with its real values: put EXPLAIN in front and run it</span>
</code></pre></div></div>

Drawn to scale, the gap looks like this:

```text
rows examined   5,340,000  ##################################################
rows sent           1,170  |
```

The query reads 4,564 rows for every row it returns, and because the count never changes between runs, those rows are the entire table. That's the simplest kind of slow: a query reading far more than it needs.

Other queries are slow in other ways, and each has its own signature in the block:

| What I see in the block | Usually means | Check next |
|---|---|---|
| `Rows examine` far above `Rows sent` (rank 1) | No usable index | `EXPLAIN`: `type` and `key` |
| `Rows sent` at a round number, millions examined (rank 4) | A `LIMIT` after a full sort | `EXPLAIN`: `Using filesort` |
| `Lock time` close to `Exec time` (rank 3) | Waiting on another transaction | What else writes those rows. An index will not help |
| Few runs, high R/Call, low V/M (rank 2) | A scheduled job | Who waits for it |
| Many runs, moderate R/Call (rank 6) | An application request path | Can it run less often or fetch less |
| High V/M (rank 1) | Runtime depends on something outside the query | Do slow runs cluster by time of day or by parameter |

## EXPLAIN: why is it slow?

The block ends with the query ready to explain, so ask MySQL:

<div class="language-text highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">*************************** 1. row ***************************</span>
<span class="c">           id: 1</span>
<span class="c">  select_type: SIMPLE</span>
<span class="c">        table: users</span>
<span class="c">   partitions: NULL</span>
         type: <span class="nf">ALL</span>            <span class="k">&lt;-- reads every row in the table</span>
possible_keys: <span class="nf">NULL</span>           <span class="k">&lt;-- no index on status or last_login</span>
          key: <span class="nf">NULL</span>           <span class="k">&lt;-- so none is used</span>
<span class="c">      key_len: NULL</span>
<span class="c">          ref: NULL</span>
         rows: <span class="nf">5192014</span>        <span class="k">&lt;-- estimate from statistics (real: 5,340,000)</span>
     filtered: <span class="nf">3.33</span>           <span class="k">&lt;-- guess: 3.33% pass the WHERE (real: 0.02%)</span>
        Extra: <span class="nf">Using where</span>    <span class="k">&lt;-- the filter runs on each row after reading it</span>
</code></pre></div></div>

Neither column is indexed, so MySQL reads every row and filters as it goes. Other plans go wrong in other ways, and some of the causes show in the query text itself:

| What I see | Means | Usual fix |
|---|---|---|
| `type: ALL`, `key: NULL` | Full scan | Index the `WHERE`: equality columns first, then the range |
| `possible_keys` set, `key: NULL` | MySQL expects a scan to be cheaper | Check the column order |
| `Using filesort` | Sorted after reading | An index ending with the `ORDER BY` column |
| `Using temporary` | A temporary table for `GROUP BY` or `DISTINCT` | Index the grouping columns |
| `YEAR(created_at) = 2025` (rank 2) | The function hides the column from its index | A range on the bare column |
| `LIKE '%lamp%'` (rank 6) | A leading wildcard defeats a B-tree index | `FULLTEXT`, or search outside MySQL |

## The fix: is it worth it?

The fix here is an index on both columns:

```sql
ALTER TABLE users ADD INDEX idx_status_last_login (status, last_login);
```

Column order matters. `status` is compared for equality and `last_login` against a range, so `status` goes first. With the columns reversed, MySQL ignored the index and scanned anyway, because 88% of the rows fall before the cutoff date.

Here is the same `EXPLAIN` before and after:

<div class="language-text highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="k">BEFORE                            AFTER  (status, last_login) index</span>
<span class="c">           id: 1                             id: 1</span>
<span class="c">  select_type: SIMPLE               select_type: SIMPLE</span>
<span class="c">        table: users                      table: users</span>
<span class="c">   partitions: NULL                  partitions: NULL</span>
         type: <span class="nf">ALL</span>                         type: <span class="s">range</span>
possible_keys: <span class="nf">NULL</span>               possible_keys: <span class="s">idx_status_last_login</span>
          key: <span class="nf">NULL</span>                         key: <span class="s">idx_status_last_login</span>
      key_len: <span class="nf">NULL</span>                     key_len: <span class="s">71</span>
<span class="c">          ref: NULL                         ref: NULL</span>
         rows: <span class="nf">5192014</span>                     rows: <span class="s">1170</span>
     filtered: <span class="nf">3.33</span>                    filtered: <span class="s">100.00</span>
        Extra: <span class="nf">Using where</span>                Extra: <span class="s">Using index condition</span>
</code></pre></div></div>

And the actual row counts, measured with `long_query_time = 0`:

| | Before | After |
|---|---|---|
| Rows examined | 5,340,000 | 1,170 |
| Rows sent | 1,170 | 1,170 |

That was easy to justify, and the example is simple on purpose: one table, one missing index, no competing queries. **Real cases are rarely this clean.** An index speeds up one read, and every write to the table pays for it, as can other queries that share the table. The following checklist helps you understand how the table and its queries are used:

<dl class="checks">
<dt markdown="span">How often is the table written, and do the writes change the indexed columns?</dt>
<dd markdown="span">Every insert, and every update to an indexed column, also updates the index.</dd>
<dd class="checks__where" markdown="span">`performance_schema.table_io_waits_summary_by_table`, and the code that writes to the table</dd>
<dt markdown="span">What other queries read this table?</dt>
<dd markdown="span">One index may serve several of them, or the optimizer may switch a query you didn't touch over to it.</dd>
<dd class="checks__where" markdown="span">other rows of the profile on the same table, then `EXPLAIN` on each</dd>
<dt markdown="span">Why does the query run at all?</dt>
<dd markdown="span">Start from the problem it solves: who uses the result, how fresh it has to be, and how quickly they need it. Those constraints decide your options. If the list of inactive users feeds a nightly cleanup, it can run once a night, on a replica, or from a cached result, and may not need an index at all. If a person waits for it on every request, it has to be fast and current, and the index is the right tool.</dd>
<dd class="checks__where" markdown="span">the code that calls it, and whoever owns that feature</dd>
<dt markdown="span">Can the server take the index build right now?</dt>
<dd markdown="span">InnoDB builds it without blocking writes, but it still reads the whole table.</dd>
<dd class="checks__where" markdown="span">the table size, and when the server is quiet</dd>
</dl>

Back to `users`. The report can't tell you why the query runs, but the application code can: it powers the dormant accounts page in the back office. Support staff open that page all day and wait half a minute each time, so the list has to be current, and a nightly batch won't do.

The index does have a cost. `last_login` changes on every login, so every login now updates the index too. But no other query in the profile touches `users`, and this one takes 41% of the logged time, so I'd add it.

Don't expect the next report to show this query running faster. It won't appear at all, because it no longer crosses `long_query_time`.

## On your own report

When you run this on your own slow log, a few commands save a lot of scrolling:

```bash
pt-query-digest slow.log > report.txt

# Just the profile
sed -n '/^# Profile/,/^# MISC/p' report.txt

# Jump to a query's block, using an ID from the profile
grep -n "ID <query id>" report.txt

# The raw slow log entry behind a block that ends "at byte <offset>"
tail -c +<offset> slow.log | head -5
```

## What the report can't tell you

Read in this order, the report tells you where the time goes, which queries cost it, and what kind of slow each one is, and `EXPLAIN` tells you why. None of that decides what to do. In the profile, rank 1 and rank 2 were just the two biggest numbers. Telling them apart, and deciding that an index on `users` was worth extra work on every login, took knowing how the system is used.

**That part is yours.**

Sometimes a slow query is a tradeoff someone made on purpose, and sometimes the fix is riskier than the problem it solves. Deciding the next step means immersing yourself in the problem the query serves: who depends on it, what it's for, and what else a change would touch.

## Further Reading

**[MySQL Performance Blog](https://www.percona.com/blog/)**  
  Percona's official blog provides deep dives into MySQL performance tuning, optimization tips, and case studies.

**[pt-query-digest Manual](https://docs.percona.com/percona-toolkit/pt-query-digest.html)**  
  Official documentation for `pt-query-digest` which explains its features and how to interpret its reports.

**[Percona Monitoring and Management (PMM)](https://www.percona.com/software/pmm)**
  An open source database monitoring, observability, and management tool.

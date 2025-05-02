---
title: '🐢 Reading a `pt-query-digest` Report Without Losing Your Mind'
date: 2025-05-02 00:00:00
featured_image: ''
excerpt: 🐢 A quick guide to decoding pt-query-digest reports and fixing slow MySQL queries.
---

You've run `pt-query-digest` on your MySQL slow log. Now you’re staring at a huge wall of text and wondering what to do with it. Here's a practical breakdown of how to actually make sense of it — and fix slow queries that are dragging your database down.

---

## 1. Start with the Summary

Right at the top, you’ll see something like:

```
# 1620 total queries
# 161 unique query patterns
# Time range: April 17–30, 2025
# Exec time avg: 22s
# Rows examined avg: 5.34M
```

**What this tells you:**
- 💀 22 seconds average execution time is alarmingly high.
- 🧐 5.34 million rows examined per query suggests indexing problems.

This section gives you a high-level health check of your workload. If it looks bad, it probably is.

---

## 2. Check the "Profile" Section

The profile ranks queries by their total response time contribution.

```
# Rank Query ID                            Response time   Calls R/Call   V
# ==== =================================== =============== ===== ======== =
#    1 0x3A250BE32D8B29F0                  12340.7 33.8%    381  32.3906  0.42
#    2 0x4B3D9E81C5C0BC7B                   4313.9 11.8%     11 392.1736  0.01
```

**How to read this:**
- 🔢 Rank: Based on total response time.
- 🧠 Query ID: A fingerprint of the query (use it to search further down).
- ⏱ Response Time: How long this query took in total (and % of the total).
- 🔁 Calls: How many times this query ran.
- ⚠️ R/Call: Average time per execution — high values here are red flags.

---

## 3. Analyze Each Query Section

Scroll down for details on each top query. You’ll see blocks like:

```
# Query 1: 381 QPS, 12.34ks total, 33.8% of all time...
# Rank: 1
# Time range: 2025-04-17 to 2025-04-30
#
# Attribute    pct   total     min     max     avg     95%  stddev  median
# ============ === ======= ======= ======= ======= ======= ======= =======
# Count          23     381
# Exec time      33 12341s      1s    160s     32s     70s     24s     28s
```

Look for:
- Execution time patterns — are they spiky?
- High max or 95th percentile values? That’s trouble.
- Rows examined vs rows sent — are we reading too much and returning too little?

Then you’ll find:

```
# Tables
SHOW TABLE STATUS FROM `database` LIKE 'users'\G
SHOW CREATE TABLE `database`.`users`\G
EXPLAIN SELECT * FROM users WHERE last_login < '2025-01-01' AND status = 'inactive'\G
```

Check:
- Are there missing indexes?
- Are we scanning the whole table (`type: ALL`)?
- Is MySQL using a key (`key: NULL` means no index was used)?

---

## 4. Know the Red Flags 🚩

Watch out for:

- ⏳ High average time per call with low execution count → likely reporting/batch jobs.
- 🔁 High call counts with moderate execution time → small optimizations can have huge payoff.
- 📊 Rows examined >> Rows sent → indexing issues.
- 🔐 High lock time → contention problems.
- ❗ EXPLAIN mentions:
  - `Using filesort`
  - `Using temporary`
  - `type: ALL`
  - `key: NULL`
- 🧮 Functions on indexed columns: `DATE(created_at)`, `MONTH(...)`, etc.

---

## 5. Prioritize Wisely

Focus on the queries that:

- Take up >10% of total time
- Are called hundreds or thousands of times
- Examine huge numbers of rows unnecessarily
- Lock up tables or create contention

---

## 6. Fix Them 🛠

Once you’ve picked your top offenders:

- ✅ Add or adjust indexes (on WHERE, JOIN, GROUP BY columns)
- 🔄 Rewrite queries for better execution plans
- 💡 Avoid functions in WHERE clauses that disable indexes
- 🧊 Cache results when appropriate
- 🔍 Use `EXPLAIN` to check what MySQL is doing behind the scenes

---

## Bonus: Use Grep to Automate the Hunt

```bash
# Profile section
grep -A 10 "# Profile" slow-queries.txt

# High row scan, low return
grep -A 20 "Rows examine.*M" slow-queries.txt

# Filesorts or temp tables
grep -A 10 "Using temporary" slow-queries.txt
grep -A 10 "Using filesort" slow-queries.txt

# Full table scans
grep -A 10 "type: ALL" slow-queries.txt
grep -A 10 "key: NULL" slow-queries.txt

# Lock time issues
grep -A 5 "Lock time.*[0-9]s" slow-queries.txt
```

---

## TL;DR 🧠

- 🔍 Start with the Profile section
- 🚨 Look for high response time or bad EXPLAIN signs
- ⚙️ Focus on top 5–10 offenders
- 🔧 Fix indexes, rewrite bad queries, reduce rows examined
- Slow queries are normal. Staying blind to them isn’t. Learn the patterns, spot the pain points, and chip away at them. Your database — and your users — will notice.
> **Note:** While tools like `pt-query-digest` provide powerful insights, nothing replaces understanding the **context** in which these queries run. Sometimes, there are valid tradeoffs that justify a "slow" query, or cases where taking action could cause more disruption than leaving things as they are—*at least for the time being*. Use the data to inform your decisions, **but don't skip the thinking part**.

---
## Further Reading

If you're interested in diving deeper into query optimization, MySQL performance, and related topics, check out the following resources:

**[MySQL Performance Blog](https://www.percona.com/blog/)**  
  Percona's official blog provides deep dives into MySQL performance tuning, optimization tips, and case studies.

**[pt-query-digest Manual](https://www.percona.com/doc/percona-toolkit/pt-query-digest.html)**  
  Official documentation for `pt-query-digest` which explains its features and how to interpret its reports.

**[Percona Monitoring and Management (PMM)](https://www.percona.com/software/pmm)**
  An open source database monitoring, observability, and management tool.




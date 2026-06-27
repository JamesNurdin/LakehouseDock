WITH profit_lo AS (
    SELECT
        lo_custkey,
        lo_suppkey,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_orderkey,
        lo_revenue - lo_supplycost AS profit
    FROM lineorder
)
SELECT
    s.s_region,
    c.c_mktsegment,
    sum(pl.lo_revenue) AS total_revenue,
    sum(pl.lo_supplycost) AS total_supplycost,
    sum(pl.profit) AS total_profit,
    avg(pl.lo_discount) AS avg_discount,
    count(distinct pl.lo_orderkey) AS order_cnt,
    count(distinct pl.lo_custkey) AS distinct_customer_cnt
FROM profit_lo pl
JOIN customer c
    ON pl.lo_custkey = c.c_custkey
JOIN supplier s
    ON pl.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, c.c_mktsegment
ORDER BY total_profit DESC
LIMIT 20

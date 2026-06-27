WITH profit_lineorder AS (
    SELECT
        lo_orderkey,
        lo_linenumber,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_revenue,
        lo_supplycost,
        (lo_revenue - lo_supplycost) AS profit
    FROM lineorder
    WHERE lo_discount < 5
)
SELECT
    c.c_region,
    s.s_region,
    p.p_category,
    SUM(pl.profit) AS total_profit,
    SUM(pl.lo_revenue) AS total_revenue,
    COUNT(*) AS order_line_count
FROM profit_lineorder pl
JOIN customer c ON pl.lo_custkey = c.c_custkey
JOIN supplier s ON pl.lo_suppkey = s.s_suppkey
JOIN part p ON pl.lo_partkey = p.p_partkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
  AND p.p_brand1 = 'Brand#45'
GROUP BY c.c_region, s.s_region, p.p_category
ORDER BY total_profit DESC
LIMIT 10

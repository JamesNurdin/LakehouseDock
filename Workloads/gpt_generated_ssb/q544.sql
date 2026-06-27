WITH line_revenue AS (
    SELECT
        lo_orderkey,
        lo_linenumber,
        lo_custkey,
        lo_suppkey,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        lo_supplycost,
        (lo_extendedprice * (100 - lo_discount) / 100) AS revenue,
        (lo_extendedprice * (100 - lo_discount) / 100 - lo_supplycost * lo_quantity) AS profit
    FROM lineorder
    WHERE lo_quantity > 30
      AND lo_discount < 5
)
SELECT
    c.c_region,
    s.s_region,
    SUM(line_revenue.revenue) AS total_revenue,
    SUM(line_revenue.profit) AS total_profit,
    COUNT(*) AS order_line_count
FROM line_revenue
JOIN customer c
    ON line_revenue.lo_custkey = c.c_custkey
JOIN supplier s
    ON line_revenue.lo_suppkey = s.s_suppkey
GROUP BY c.c_region, s.s_region
ORDER BY total_revenue DESC
LIMIT 10

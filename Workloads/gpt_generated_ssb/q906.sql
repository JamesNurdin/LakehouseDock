/*
  Revenue, profit and discount analysis by customer region, part category and supplier nation.
  Shows the top 20 combinations where profit margin exceeds 5%.
*/
WITH region_category_supplier AS (
    SELECT
        c.c_region,
        p.p_category,
        s.s_nation,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_shipmode = 'AIR'
    GROUP BY c.c_region, p.p_category, s.s_nation
)
SELECT
    r.c_region,
    r.p_category,
    r.s_nation,
    r.total_revenue,
    r.total_profit,
    CAST(r.total_profit AS DOUBLE) / NULLIF(r.total_revenue, 0) AS profit_margin,
    r.avg_discount,
    r.order_count
FROM region_category_supplier r
WHERE CAST(r.total_profit AS DOUBLE) / NULLIF(r.total_revenue, 0) > 0.05
ORDER BY r.total_revenue DESC
LIMIT 20

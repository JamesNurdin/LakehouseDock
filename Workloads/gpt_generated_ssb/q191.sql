WITH revenue_by_regions AS (
    SELECT
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        p.p_category AS part_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        SUM(lo.lo_quantity) AS total_quantity,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    GROUP BY c.c_region, s.s_region, p.p_category
)
SELECT
    customer_region,
    supplier_region,
    part_category,
    total_revenue,
    total_profit,
    total_quantity,
    order_cnt,
    total_profit / total_revenue AS profit_margin
FROM revenue_by_regions
WHERE total_revenue > 0
ORDER BY total_revenue DESC
LIMIT 30

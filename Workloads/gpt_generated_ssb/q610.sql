WITH revenue_per_lineorder AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        lo_extendedprice * (1 - lo_discount / 100.0) AS revenue
    FROM lineorder
)
SELECT
    c.c_region,
    p.p_category,
    s.s_nation,
    SUM(r.revenue) AS total_revenue,
    SUM(r.lo_quantity) AS total_quantity,
    COUNT(*) AS order_count
FROM revenue_per_lineorder r
JOIN customer c ON r.lo_custkey = c.c_custkey
JOIN part p ON r.lo_partkey = p.p_partkey
JOIN supplier s ON r.lo_suppkey = s.s_suppkey
WHERE c.c_region = 'ASIA'
GROUP BY c.c_region, p.p_category, s.s_nation
ORDER BY total_revenue DESC
LIMIT 20

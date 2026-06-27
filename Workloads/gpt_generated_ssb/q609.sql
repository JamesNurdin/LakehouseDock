WITH filtered_lo AS (
    SELECT lo_orderkey,
           lo_custkey,
           lo_partkey,
           lo_revenue,
           lo_quantity,
           lo_orderdate
    FROM lineorder
    WHERE lo_quantity > 0
      AND lo_orderdate BETWEEN 19940101 AND 19941231
)
SELECT
    c.c_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count,
    AVG(lo.lo_revenue / lo.lo_quantity) AS avg_revenue_per_quantity
FROM filtered_lo lo
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
WHERE c.c_region IS NOT NULL
GROUP BY c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10

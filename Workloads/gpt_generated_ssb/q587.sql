WITH filtered_orders AS (
    SELECT
        lo_orderkey,
        lo_revenue,
        lo_discount,
        lo_quantity,
        lo_partkey,
        lo_suppkey
    FROM lineorder
    WHERE lo_quantity > 30
)
SELECT
    p.p_category,
    s.s_region,
    sum(f.lo_revenue) AS total_revenue,
    avg(f.lo_discount) AS avg_discount,
    count(DISTINCT f.lo_orderkey) AS order_count
FROM filtered_orders f
JOIN part p ON f.lo_partkey = p.p_partkey
JOIN supplier s ON f.lo_suppkey = s.s_suppkey
WHERE p.p_size BETWEEN 10 AND 20
GROUP BY p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 10

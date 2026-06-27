WITH filtered_lo AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_quantity,
        lo_discount,
        lo_revenue
    FROM lineorder
    WHERE lo_orderdate BETWEEN 19940101 AND 19941231
)
SELECT
    s.s_region,
    p.p_category,
    SUM(fl.lo_revenue) AS total_revenue,
    SUM(fl.lo_quantity) AS total_quantity,
    AVG(fl.lo_discount) AS avg_discount
FROM filtered_lo fl
JOIN supplier s ON fl.lo_suppkey = s.s_suppkey
JOIN part p ON fl.lo_partkey = p.p_partkey
JOIN customer c ON fl.lo_custkey = c.c_custkey
WHERE c.c_region = 'AMERICA'
GROUP BY s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10

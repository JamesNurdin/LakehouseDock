WITH lo_agg AS (
    SELECT
        lo_custkey,
        lo_partkey,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        SUM(lo_quantity) AS total_quantity
    FROM lineorder
    GROUP BY lo_custkey, lo_partkey
)
SELECT
    c.c_region,
    p.p_category,
    SUM(lo_agg.total_revenue) AS revenue,
    SUM(lo_agg.total_profit)   AS profit,
    SUM(lo_agg.total_quantity) AS quantity
FROM lo_agg
JOIN customer c ON lo_agg.lo_custkey = c.c_custkey
JOIN part p      ON lo_agg.lo_partkey = p.p_partkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
GROUP BY c.c_region, p.p_category
ORDER BY revenue DESC
LIMIT 100

WITH lo_summary AS (
    SELECT
        lo_custkey,
        lo_partkey,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost * lo_quantity) AS total_supplycost,
        SUM(lo_quantity) AS total_quantity,
        AVG(lo_discount) AS avg_discount
    FROM lineorder
    WHERE lo_shipmode = 'AIR'
    GROUP BY lo_custkey, lo_partkey
)
SELECT
    c.c_region,
    p.p_category,
    SUM(lo_summary.total_revenue) AS total_revenue,
    SUM(lo_summary.total_supplycost) AS total_supplycost,
    SUM(lo_summary.total_revenue - lo_summary.total_supplycost) AS total_profit,
    SUM(lo_summary.total_quantity) AS total_quantity,
    AVG(lo_summary.avg_discount) AS avg_discount
FROM lo_summary
JOIN customer c ON lo_summary.lo_custkey = c.c_custkey
JOIN part p ON lo_summary.lo_partkey = p.p_partkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
  AND p.p_category = 'MFGR#12'
GROUP BY c.c_region, p.p_category
ORDER BY total_profit DESC
LIMIT 10

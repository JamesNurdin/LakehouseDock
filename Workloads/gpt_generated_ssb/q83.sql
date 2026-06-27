WITH regional_shipmode_stats AS (
    SELECT
        c.c_region,
        lo.lo_shipmode,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS lineorder_count,
        COUNT(DISTINCT c.c_custkey) AS distinct_customers
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
      AND lo.lo_discount > 0
    GROUP BY
        c.c_region,
        lo.lo_shipmode
)
SELECT
    c_region,
    lo_shipmode,
    total_revenue,
    avg_discount,
    lineorder_count,
    distinct_customers,
    total_revenue / NULLIF(lineorder_count, 0) AS avg_revenue_per_line,
    rank() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS revenue_rank
FROM regional_shipmode_stats
ORDER BY total_revenue DESC
LIMIT 20

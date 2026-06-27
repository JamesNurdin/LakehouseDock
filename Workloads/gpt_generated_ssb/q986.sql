/*
   Revenue and order analysis by customer region and market segment
   Uses the lineorder and customer tables from the SSB dataset.
*/
WITH region_segment_stats AS (
    SELECT
        c.c_region,
        c.c_mktsegment,
        SUM(lo.lo_revenue) AS revenue,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE lo.lo_quantity > 0
    GROUP BY c.c_region, c.c_mktsegment
)
SELECT
    rs.c_region AS region,
    rs.c_mktsegment AS market_segment,
    rs.revenue,
    rs.order_count,
    rs.total_quantity,
    rs.avg_discount,
    RANK() OVER (PARTITION BY rs.c_region ORDER BY rs.revenue DESC) AS revenue_rank_within_region
FROM region_segment_stats rs
ORDER BY rs.revenue DESC
LIMIT 20

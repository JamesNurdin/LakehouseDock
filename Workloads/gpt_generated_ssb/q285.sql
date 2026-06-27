/*
  Revenue and discount analysis per customer region and market segment.
  Uses only the customer and lineorder tables and the allowed join condition.
*/
WITH lo_filtered AS (
    SELECT
        lo.lo_custkey,
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_quantity
    FROM lineorder lo
    WHERE lo.lo_quantity > 0
),
region_metrics AS (
    SELECT
        c.c_region,
        c.c_mktsegment,
        SUM(lf.lo_revenue) AS total_revenue,
        AVG(lf.lo_discount) AS avg_discount,
        COUNT(DISTINCT lf.lo_orderkey) AS distinct_order_cnt,
        SUM(lf.lo_quantity) AS total_quantity
    FROM lo_filtered lf
    JOIN customer c
        ON lf.lo_custkey = c.c_custkey
    GROUP BY c.c_region, c.c_mktsegment
)
SELECT
    rm.c_region,
    rm.c_mktsegment,
    rm.total_revenue,
    rm.avg_discount,
    rm.distinct_order_cnt,
    rm.total_quantity,
    RANK() OVER (ORDER BY rm.total_revenue DESC) AS revenue_rank
FROM region_metrics rm
ORDER BY rm.total_revenue DESC

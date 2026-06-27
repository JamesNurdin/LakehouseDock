WITH filtered_lineorder AS (
    SELECT
        lo_custkey,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_shipmode,
        lo_orderkey
    FROM lineorder
    WHERE lo_shipmode IN ('AIR', 'RAIL')
      AND lo_discount BETWEEN 5 AND 15
),
aggregated AS (
    SELECT
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS num_orders
    FROM filtered_lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE c.c_region = 'ASIA'
    GROUP BY c.c_region, c.c_nation, c.c_mktsegment
)
SELECT
    a.c_region,
    a.c_nation,
    a.c_mktsegment,
    a.total_revenue,
    a.total_profit,
    a.avg_discount,
    a.num_orders,
    ROW_NUMBER() OVER (ORDER BY a.total_revenue DESC) AS revenue_rank
FROM aggregated a
ORDER BY a.total_revenue DESC
LIMIT 10

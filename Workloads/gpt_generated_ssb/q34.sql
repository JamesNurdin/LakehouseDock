WITH revenue_by_seg AS (
    SELECT
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_extendedprice
    FROM lineorder lo
    JOIN customer c
      ON lo.lo_custkey = c.c_custkey
    WHERE lo.lo_quantity > 0
),
agg AS (
    SELECT
        c_region,
        c_nation,
        c_mktsegment,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_discount) AS total_discount,
        AVG(lo_quantity) AS avg_quantity,
        SUM(lo_extendedprice) AS total_extendedprice
    FROM revenue_by_seg
    GROUP BY c_region, c_nation, c_mktsegment
)
SELECT
    c_region,
    c_nation,
    c_mktsegment,
    distinct_orders,
    total_revenue,
    total_discount,
    avg_quantity,
    total_extendedprice,
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY total_revenue DESC
LIMIT 50

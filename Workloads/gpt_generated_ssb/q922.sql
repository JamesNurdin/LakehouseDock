WITH lo_agg AS (
    SELECT
        lo_suppkey,
        lo_shipmode,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        COUNT(*) AS order_cnt
    FROM lineorder
    WHERE lo_orderdate BETWEEN 19940101 AND 19941231
      AND lo_discount BETWEEN 0 AND 5
    GROUP BY lo_suppkey, lo_shipmode
),
region_shipmode_rev AS (
    SELECT
        s.s_region,
        lo_agg.lo_shipmode,
        SUM(lo_agg.total_revenue) AS revenue,
        SUM(lo_agg.total_supplycost) AS supply_cost,
        SUM(lo_agg.total_revenue) - SUM(lo_agg.total_supplycost) AS profit,
        SUM(lo_agg.order_cnt) AS orders,
        ROW_NUMBER() OVER (PARTITION BY s.s_region ORDER BY SUM(lo_agg.total_revenue) DESC) AS region_rank
    FROM lo_agg
    JOIN supplier s ON lo_agg.lo_suppkey = s.s_suppkey
    GROUP BY s.s_region, lo_agg.lo_shipmode
)
SELECT
    s_region,
    lo_shipmode,
    revenue,
    profit,
    orders
FROM region_shipmode_rev
WHERE region_rank <= 3
ORDER BY s_region, revenue DESC

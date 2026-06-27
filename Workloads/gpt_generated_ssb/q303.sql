-- Analytical query: revenue and order metrics per customer region and market segment for Asian customers shipping via AIR, with ranking by revenue
WITH cust_orders AS (
    SELECT
        c.c_custkey,
        c.c_region,
        c.c_mktsegment,
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_shipmode
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE c.c_region = 'ASIA'
      AND lo.lo_shipmode = 'AIR'
),
agg AS (
    SELECT
        c_region,
        c_mktsegment,
        COUNT(DISTINCT lo_orderkey) AS order_count,
        SUM(lo_quantity) AS total_quantity,
        SUM(lo_revenue) AS total_revenue,
        AVG(lo_discount) AS avg_discount
    FROM cust_orders
    GROUP BY c_region, c_mktsegment
),
final AS (
    SELECT
        c_region,
        c_mktsegment,
        order_count,
        total_quantity,
        total_revenue,
        avg_discount,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM agg
)
SELECT
    c_region,
    c_mktsegment,
    order_count,
    total_quantity,
    total_revenue,
    avg_discount,
    revenue_rank
FROM final
ORDER BY revenue_rank

/* Analytical query: revenue and order metrics per customer region, nation, and market segment */
WITH cust_lineorder AS (
    SELECT
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_quantity
    FROM lineorder lo
    JOIN customer c
      ON lo.lo_custkey = c.c_custkey
    WHERE c.c_region = 'ASIA'
),
region_metrics AS (
    SELECT
        c_region,
        c_nation,
        c_mktsegment,
        COUNT(DISTINCT lo_orderkey) AS num_orders,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_quantity) AS total_quantity,
        AVG(lo_discount) AS avg_discount
    FROM cust_lineorder
    GROUP BY c_region, c_nation, c_mktsegment
)
SELECT
    c_region,
    c_nation,
    c_mktsegment,
    num_orders,
    total_revenue,
    total_quantity,
    avg_discount,
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM region_metrics
ORDER BY total_revenue DESC
LIMIT 10

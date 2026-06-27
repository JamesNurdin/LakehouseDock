WITH customer_revenue AS (
    SELECT
        lo.lo_custkey,
        cu.c_region,
        cu.c_mktsegment,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer cu
        ON lo.lo_custkey = cu.c_custkey
    WHERE lo.lo_quantity > 5
    GROUP BY lo.lo_custkey, cu.c_region, cu.c_mktsegment
)
SELECT
    c_region,
    c_mktsegment,
    lo_custkey,
    total_revenue,
    total_profit,
    order_cnt,
    avg_discount,
    RANK() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS region_revenue_rank
FROM customer_revenue
WHERE total_revenue > 1000000
ORDER BY c_region, region_revenue_rank
LIMIT 20

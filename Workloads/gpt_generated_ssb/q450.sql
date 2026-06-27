WITH customer_revenue AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_region,
        c.c_mktsegment,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_region, c.c_mktsegment
),
region_rank AS (
    SELECT
        c_custkey,
        c_name,
        c_region,
        c_mktsegment,
        total_revenue,
        total_quantity,
        avg_discount,
        ROW_NUMBER() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS region_revenue_rank
    FROM customer_revenue
)
SELECT
    c_custkey,
    c_name,
    c_region,
    c_mktsegment,
    total_revenue,
    total_quantity,
    avg_discount,
    region_revenue_rank
FROM region_rank
WHERE region_revenue_rank <= 5
ORDER BY c_region, region_revenue_rank

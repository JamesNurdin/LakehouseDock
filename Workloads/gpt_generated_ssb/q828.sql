WITH revenue_by_region_category AS (
    SELECT
        customer.c_region,
        part.p_category,
        SUM(lineorder.lo_revenue) AS total_revenue,
        AVG(lineorder.lo_discount) AS avg_discount,
        COUNT(DISTINCT lineorder.lo_orderkey) AS order_count
    FROM lineorder
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    WHERE lineorder.lo_shipmode = 'AIR'
      AND customer.c_region = 'ASIA'
    GROUP BY customer.c_region, part.p_category
)
SELECT
    c_region,
    p_category,
    total_revenue,
    avg_discount,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS category_rank,
    SUM(total_revenue) OVER (
        PARTITION BY c_region
        ORDER BY total_revenue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM revenue_by_region_category
ORDER BY c_region, category_rank

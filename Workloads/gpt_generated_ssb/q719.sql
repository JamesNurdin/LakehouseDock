WITH revenue_by_supplier AS (
    SELECT
        s_region,
        s_city,
        s_name,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_quantity) AS total_quantity,
        AVG(lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM lineorder
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE lo_orderdate BETWEEN 19940101 AND 19941231
    GROUP BY s_region, s_city, s_name
)
SELECT
    s_region,
    s_city,
    s_name,
    total_revenue,
    total_quantity,
    avg_discount,
    order_count,
    RANK() OVER (PARTITION BY s_region ORDER BY total_revenue DESC) AS region_revenue_rank,
    PERCENT_RANK() OVER (PARTITION BY s_region ORDER BY total_revenue) AS region_revenue_percent_rank,
    SUM(total_revenue) OVER (PARTITION BY s_region) AS region_total_revenue
FROM revenue_by_supplier
WHERE total_revenue > 1000000
ORDER BY s_region, region_revenue_rank

/* Revenue and order count by region and part category, with ranking per region */
WITH revenue_by_region_category AS (
    SELECT
        c.c_region,
        p.p_category,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS total_revenue,
        COUNT(*) AS order_cnt
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE lo.lo_quantity > 24
      AND lo.lo_discount BETWEEN 5 AND 7
    GROUP BY c.c_region, p.p_category
)
SELECT
    c_region,
    p_category,
    total_revenue,
    order_cnt,
    RANK() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS category_rank_in_region
FROM revenue_by_region_category
ORDER BY c_region, category_rank_in_region

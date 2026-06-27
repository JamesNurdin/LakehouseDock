WITH revenue_by_region_category AS (
    SELECT
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
      AND p.p_brand1 = 'Brand#12'
    GROUP BY c.c_region, p.p_category
)
SELECT
    c_region,
    p_category,
    total_revenue,
    total_quantity,
    avg_discount,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_region_category
WHERE total_revenue > 1000000
ORDER BY total_revenue DESC

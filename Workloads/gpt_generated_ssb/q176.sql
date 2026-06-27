WITH revenue_by_region_category AS (
    SELECT
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE c.c_region = 'ASIA'
      AND p.p_size > 15
    GROUP BY c.c_region, p.p_category
)
SELECT
    c_region,
    p_category,
    total_revenue,
    avg_discount,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_region_category
ORDER BY total_revenue DESC

WITH revenue_by_region_category AS (
    SELECT
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count,
        SUM(lo.lo_quantity) AS total_quantity
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
      AND p.p_brand1 = 'Brand#12'
    GROUP BY c.c_region, p.p_category
)
SELECT
    c_region,
    p_category,
    total_revenue,
    avg_discount,
    order_count,
    total_quantity,
    total_revenue / SUM(total_revenue) OVER () AS revenue_share
FROM revenue_by_region_category
ORDER BY total_revenue DESC
LIMIT 10

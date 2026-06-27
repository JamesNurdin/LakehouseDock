WITH part_sales AS (
    SELECT
        p.p_category,
        p.p_brand1,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS order_cnt
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE c.c_region = 'ASIA'
      AND lo.lo_orderdate BETWEEN 19940101 AND 19941231
    GROUP BY p.p_category, p.p_brand1
)
SELECT
    p_category,
    p_brand1,
    total_revenue,
    avg_discount,
    order_cnt,
    RANK() OVER (PARTITION BY p_category ORDER BY total_revenue DESC) AS brand_rank_in_category,
    total_revenue * (1 - avg_discount / 100.0) AS net_revenue_estimate
FROM part_sales
WHERE total_revenue > 1000000
ORDER BY p_category, brand_rank_in_category
LIMIT 20

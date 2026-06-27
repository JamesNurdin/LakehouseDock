WITH part_revenue AS (
    SELECT
        p.p_category,
        p.p_brand1,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE lo.lo_quantity > 0
    GROUP BY p.p_category, p.p_brand1
),
category_rank AS (
    SELECT
        p_category,
        p_brand1,
        total_revenue,
        total_quantity,
        avg_discount,
        order_cnt,
        RANK() OVER (PARTITION BY p_category ORDER BY total_revenue DESC) AS brand_rank
    FROM part_revenue
)
SELECT
    p_category,
    p_brand1,
    total_revenue,
    total_quantity,
    avg_discount,
    order_cnt,
    brand_rank
FROM category_rank
WHERE total_revenue > 1000000
ORDER BY p_category, brand_rank

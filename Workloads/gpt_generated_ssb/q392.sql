WITH part_revenue AS (
    SELECT
        p.p_category,
        p.p_brand1,
        p.p_name,
        p.p_size,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN part p
      ON lo.lo_partkey = p.p_partkey
    WHERE p.p_size BETWEEN 10 AND 20
    GROUP BY p.p_category, p.p_brand1, p.p_name, p.p_size
)
SELECT
    pr.p_category,
    pr.p_brand1,
    pr.p_name,
    pr.p_size,
    pr.total_revenue,
    pr.total_quantity,
    pr.avg_discount,
    RANK() OVER (PARTITION BY pr.p_category ORDER BY pr.total_revenue DESC) AS revenue_rank
FROM part_revenue pr
WHERE pr.total_quantity > 500
ORDER BY pr.p_category, revenue_rank
LIMIT 100

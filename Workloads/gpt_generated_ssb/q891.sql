WITH part_sales AS (
    SELECT
        part.p_category,
        part.p_brand1,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_revenue - lineorder.lo_supplycost * lineorder.lo_quantity) AS total_profit,
        AVG(lineorder.lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM lineorder
    JOIN part ON lineorder.lo_partkey = part.p_partkey
    WHERE lineorder.lo_quantity > 30
      AND lineorder.lo_discount BETWEEN 0 AND 10
    GROUP BY part.p_category, part.p_brand1
)
SELECT
    p_category,
    p_brand1,
    total_revenue,
    total_profit,
    avg_discount,
    order_count,
    total_revenue / SUM(total_revenue) OVER () AS revenue_share,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM part_sales
ORDER BY total_revenue DESC
LIMIT 20

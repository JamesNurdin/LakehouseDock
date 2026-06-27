WITH category_brand_profit AS (
    SELECT
        p_category,
        p_brand1,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders,
        SUM(lo_quantity) AS total_quantity
    FROM lineorder
    JOIN part ON lineorder.lo_partkey = part.p_partkey
    WHERE lo_quantity > 0
    GROUP BY p_category, p_brand1
)
SELECT
    p_category,
    p_brand1,
    total_revenue,
    total_supplycost,
    total_profit,
    avg_discount,
    distinct_orders,
    total_quantity,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM category_brand_profit
ORDER BY profit_rank
LIMIT 10

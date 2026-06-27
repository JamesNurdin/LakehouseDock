WITH revenue_by_part AS (
    SELECT
        p.p_category,
        p.p_brand1,
        p.p_color,
        SUM(lo.lo_extendedprice) AS total_extendedprice,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        COUNT(*) AS order_count
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE lo.lo_quantity > 0
    GROUP BY p.p_category, p.p_brand1, p.p_color
)
SELECT
    p_category,
    p_brand1,
    p_color,
    total_extendedprice,
    total_revenue,
    total_supplycost,
    total_profit,
    order_count
FROM revenue_by_part
ORDER BY total_profit DESC
LIMIT 10

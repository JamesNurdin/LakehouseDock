WITH lineorder_filtered AS (
    SELECT
        lo_partkey,
        lo_quantity,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_revenue - lo_supplycost AS profit
    FROM lineorder
    WHERE lo_quantity > 10
      AND lo_discount BETWEEN 0 AND 10
),
joined AS (
    SELECT
        p_category,
        p_brand1,
        lo_revenue,
        profit,
        lo_discount
    FROM lineorder_filtered
    JOIN part ON lineorder_filtered.lo_partkey = part.p_partkey
),
aggregated AS (
    SELECT
        p_category,
        p_brand1,
        SUM(lo_revenue) AS total_revenue,
        SUM(profit) AS total_profit,
        COUNT(*) AS order_count,
        AVG(lo_discount) AS avg_discount
    FROM joined
    GROUP BY p_category, p_brand1
    HAVING SUM(lo_revenue) > 1000000
)
SELECT
    p_category,
    p_brand1,
    total_revenue,
    total_profit,
    order_count,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY p_category ORDER BY total_revenue DESC) AS brand_rank_in_category
FROM aggregated
ORDER BY total_revenue DESC
LIMIT 20

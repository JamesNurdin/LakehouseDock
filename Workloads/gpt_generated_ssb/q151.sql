WITH aggregated AS (
    SELECT
        part.p_category,
        part.p_brand1,
        part.p_color,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_quantity) AS total_quantity
    FROM lineorder
    JOIN part ON lineorder.lo_partkey = part.p_partkey
    WHERE part.p_category IN ('MFGR#12', 'MFGR#13')
    GROUP BY part.p_category, part.p_brand1, part.p_color
)
SELECT
    p_category,
    p_brand1,
    p_color,
    total_revenue,
    total_quantity,
    rank() OVER (PARTITION BY p_category ORDER BY total_revenue DESC) AS revenue_rank_within_category
FROM aggregated
ORDER BY p_category, revenue_rank_within_category
LIMIT 20

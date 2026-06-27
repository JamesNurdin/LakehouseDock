WITH revenue_by_part AS (
    SELECT
        part.p_category,
        part.p_brand1,
        part.p_type,
        SUM(lineorder.lo_revenue) AS revenue
    FROM lineorder
    JOIN part ON lineorder.lo_partkey = part.p_partkey
    GROUP BY part.p_category, part.p_brand1, part.p_type
    HAVING SUM(lineorder.lo_revenue) > 1000000
)
SELECT
    p_category,
    p_brand1,
    p_type,
    revenue,
    ROW_NUMBER() OVER (PARTITION BY p_category ORDER BY revenue DESC) AS rank_in_category
FROM revenue_by_part
ORDER BY p_category, rank_in_category

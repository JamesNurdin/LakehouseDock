WITH part_stats AS (
    SELECT
        part.p_category,
        part.p_brand1,
        SUM(lineorder.lo_extendedprice * (1 - lineorder.lo_discount / 100.0)) AS total_revenue,
        SUM(lineorder.lo_quantity) AS total_quantity,
        AVG(lineorder.lo_discount) AS avg_discount,
        COUNT(DISTINCT lineorder.lo_orderkey) AS distinct_orders
    FROM lineorder
    JOIN part ON lineorder.lo_partkey = part.p_partkey
    WHERE lineorder.lo_quantity > 0
    GROUP BY part.p_category, part.p_brand1
)
SELECT
    p_category,
    p_brand1,
    total_revenue,
    total_quantity,
    avg_discount,
    distinct_orders,
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM part_stats
ORDER BY total_revenue DESC
LIMIT 15

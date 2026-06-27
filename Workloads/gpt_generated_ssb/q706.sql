WITH part_revenue AS (
    SELECT
        part.p_partkey,
        part.p_category,
        part.p_brand1,
        part.p_type,
        SUM(lineorder.lo_revenue) AS revenue,
        SUM(lineorder.lo_quantity) AS quantity,
        COUNT(*) AS line_cnt
    FROM lineorder
    JOIN part ON lineorder.lo_partkey = part.p_partkey
    WHERE lineorder.lo_shipmode = 'AIR'
      AND lineorder.lo_orderpriority = '1-URGENT'
    GROUP BY part.p_partkey, part.p_category, part.p_brand1, part.p_type
)
SELECT
    p_category,
    p_brand1,
    p_type,
    revenue,
    quantity,
    line_cnt,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM part_revenue
WHERE revenue > 1000000
ORDER BY revenue_rank
LIMIT 10

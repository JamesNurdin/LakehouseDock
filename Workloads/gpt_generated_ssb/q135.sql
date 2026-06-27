WITH part_sales AS (
    SELECT
        lo_partkey,
        SUM(lo_extendedprice) AS total_extendedprice,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_quantity) AS total_quantity,
        AVG(lo_discount) AS avg_discount
    FROM lineorder
    WHERE lo_quantity > 20
      AND lo_shipmode = 'AIR'
    GROUP BY lo_partkey
)
SELECT
    p.p_category,
    p.p_brand1,
    p.p_color,
    p.p_size,
    ps.total_extendedprice,
    ps.total_revenue,
    ps.total_quantity,
    ps.avg_discount,
    ROW_NUMBER() OVER (ORDER BY ps.total_revenue DESC) AS revenue_rank
FROM part_sales ps
JOIN part p
    ON ps.lo_partkey = p.p_partkey
WHERE p.p_category IS NOT NULL
ORDER BY ps.total_revenue DESC
LIMIT 10

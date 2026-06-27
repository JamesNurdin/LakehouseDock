WITH cat_region_rev AS (
    SELECT
        part.p_category AS p_category,
        supplier.s_region AS s_region,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_supplycost) AS total_supplycost,
        COUNT(DISTINCT lineorder.lo_orderkey) AS order_count,
        AVG(lineorder.lo_discount) AS avg_discount
    FROM lineorder
    JOIN part ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE part.p_brand1 = 'Brand#23'
      AND supplier.s_region IN ('ASIA', 'EUROPE')
    GROUP BY part.p_category, supplier.s_region
)
SELECT
    p_category,
    s_region,
    total_revenue,
    total_supplycost,
    order_count,
    avg_discount,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM cat_region_rev
ORDER BY total_revenue DESC
LIMIT 10

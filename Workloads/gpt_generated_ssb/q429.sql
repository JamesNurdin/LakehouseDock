WITH agg AS (
    SELECT
        customer.c_region,
        part.p_category,
        supplier.s_nation,
        sum(lineorder.lo_revenue) AS total_revenue,
        avg(lineorder.lo_discount) AS avg_discount,
        sum(lineorder.lo_quantity) AS total_quantity
    FROM lineorder
    JOIN customer ON lineorder.lo_custkey = customer.c_custkey
    JOIN part ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE supplier.s_region = 'AMERICA'
      AND part.p_size > 10
      AND customer.c_mktsegment = 'AUTOMOBILE'
    GROUP BY
        customer.c_region,
        part.p_category,
        supplier.s_nation
    HAVING sum(lineorder.lo_revenue) > 1000000
)
SELECT
    agg.c_region,
    agg.p_category,
    agg.s_nation,
    agg.total_revenue,
    agg.avg_discount,
    agg.total_quantity,
    rank() OVER (PARTITION BY agg.c_region ORDER BY agg.total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY agg.c_region, revenue_rank
LIMIT 200

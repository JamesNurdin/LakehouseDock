WITH revenue_by_region AS (
    SELECT
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        SUM(lo.lo_revenue) AS total_revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_quantity > 30
      AND lo.lo_discount < 5
    GROUP BY
        c.c_region,
        s.s_region
)
SELECT
    r.customer_region,
    r.supplier_region,
    r.total_revenue,
    r.avg_discount,
    r.distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY r.customer_region ORDER BY r.total_revenue DESC) AS supplier_region_rank
FROM revenue_by_region r
ORDER BY r.customer_region, supplier_region_rank
LIMIT 50

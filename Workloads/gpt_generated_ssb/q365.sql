WITH revenue_by_region AS (
    SELECT
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        lo.lo_orderpriority AS order_priority,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
    GROUP BY c.c_region, s.s_region, lo.lo_orderpriority
)
SELECT
    customer_region,
    supplier_region,
    order_priority,
    total_revenue,
    total_quantity,
    avg_discount,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_region
ORDER BY revenue_rank
LIMIT 10

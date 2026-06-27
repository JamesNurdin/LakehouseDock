/* Revenue and discount analysis by customer and supplier regions */
WITH order_summary AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_suppkey,
        SUM(lo_revenue) AS order_revenue,
        AVG(lo_discount) AS order_avg_discount
    FROM lineorder
    GROUP BY lo_orderkey, lo_custkey, lo_suppkey
)
SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    SUM(os.order_revenue) AS total_revenue,
    AVG(os.order_avg_discount) AS avg_discount
FROM order_summary os
JOIN customer c ON os.lo_custkey = c.c_custkey
JOIN supplier s ON os.lo_suppkey = s.s_suppkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
  AND os.order_revenue > 100000
GROUP BY c.c_region, s.s_region
ORDER BY total_revenue DESC
LIMIT 10

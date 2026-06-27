WITH cust_lineorder AS (
    SELECT
        c.c_custkey,
        c.c_region,
        c.c_mktsegment,
        lo.lo_orderkey,
        lo.lo_orderpriority,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_shippriority
    FROM lineorder lo
    JOIN customer c
      ON lo.lo_custkey = c.c_custkey
    WHERE c.c_region = 'ASIA'
      AND lo.lo_shippriority > 0
)
SELECT
    c_region,
    c_mktsegment,
    lo_orderpriority,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    COUNT(DISTINCT c_custkey) AS distinct_customers
FROM cust_lineorder
GROUP BY c_region, c_mktsegment, lo_orderpriority
ORDER BY total_revenue DESC
LIMIT 10

WITH cust_orders AS (
    SELECT
        c.c_custkey,
        c.c_region,
        c.c_nation,
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE lo.lo_quantity > 10
      AND lo.lo_discount > 0
      AND c.c_region = 'ASIA'
)
SELECT
    c_region,
    c_nation,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM cust_orders
GROUP BY c_region, c_nation
HAVING SUM(lo_revenue) > 1000000
ORDER BY total_revenue DESC

WITH cust_sales AS (
    SELECT
        lo.lo_custkey,
        SUM(lo.lo_revenue) AS cust_revenue,
        SUM(lo.lo_quantity) AS cust_quantity,
        AVG(lo.lo_discount) AS cust_avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS cust_orders
    FROM lineorder lo
    GROUP BY lo.lo_custkey
)
SELECT
    c.c_region,
    c.c_nation,
    SUM(cs.cust_revenue) AS total_revenue,
    SUM(cs.cust_quantity) AS total_quantity,
    AVG(cs.cust_avg_discount) AS avg_discount,
    SUM(cs.cust_orders) AS total_orders
FROM cust_sales cs
JOIN customer c
    ON cs.lo_custkey = c.c_custkey
WHERE c.c_mktsegment = 'MACHINERY'
GROUP BY c.c_region, c.c_nation
ORDER BY total_revenue DESC
LIMIT 10

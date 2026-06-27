WITH cust_orders AS (
    SELECT
        c.c_custkey,
        c.c_region,
        c.c_mktsegment,
        lo.lo_orderpriority,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE c.c_region = 'ASIA'
)
SELECT
    co.c_region,
    co.c_mktsegment,
    co.lo_orderpriority,
    COUNT(DISTINCT co.c_custkey) AS num_customers,
    SUM(co.lo_revenue) AS total_revenue,
    AVG(co.lo_discount) AS avg_discount,
    SUM(co.lo_extendedprice) AS total_extended_price
FROM cust_orders co
GROUP BY co.c_region, co.c_mktsegment, co.lo_orderpriority
HAVING SUM(co.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 10

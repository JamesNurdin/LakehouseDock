WITH customer_orders AS (
    SELECT
        l.lo_custkey,
        SUM(l.lo_revenue) AS revenue,
        AVG(l.lo_discount) AS discount,
        COUNT(DISTINCT l.lo_orderkey) AS order_cnt
    FROM lineorder l
    WHERE l.lo_quantity > 5
    GROUP BY l.lo_custkey
)
SELECT
    c.c_region,
    c.c_mktsegment,
    SUM(co.revenue) AS total_revenue,
    AVG(co.discount) AS avg_discount,
    SUM(co.order_cnt) AS total_orders
FROM customer_orders co
JOIN customer c
    ON co.lo_custkey = c.c_custkey
WHERE c.c_nation = 'UNITED STATES'
GROUP BY c.c_region, c.c_mktsegment
ORDER BY total_revenue DESC
LIMIT 5

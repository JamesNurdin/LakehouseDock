/* Revenue, quantity, and discount analysis by customer region and market segment for AIR shipments */
WITH filtered_orders AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_revenue,
        lo_quantity,
        lo_discount,
        lo_shipmode
    FROM lineorder
    WHERE lo_shipmode = 'AIR'
)
SELECT
    c.c_region,
    c.c_mktsegment,
    SUM(f.lo_revenue) AS total_revenue,
    SUM(f.lo_quantity) AS total_quantity,
    AVG(f.lo_discount) AS avg_discount,
    COUNT(DISTINCT c.c_custkey) AS num_customers
FROM filtered_orders f
JOIN customer c
    ON f.lo_custkey = c.c_custkey
GROUP BY
    c.c_region,
    c.c_mktsegment
ORDER BY total_revenue DESC
LIMIT 10

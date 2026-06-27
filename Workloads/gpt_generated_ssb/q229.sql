WITH order_summary AS (
    SELECT
        lo_orderkey,
        lo_suppkey,
        lo_orderdate,
        SUM(lo_revenue) AS order_revenue,
        SUM(lo_supplycost) AS order_supplycost,
        SUM(lo_quantity) AS order_quantity,
        AVG(lo_discount) AS order_avg_discount
    FROM lineorder
    WHERE lo_quantity > 0
    GROUP BY lo_orderkey, lo_suppkey, lo_orderdate
)
SELECT
    s.s_region,
    o.lo_orderdate,
    COUNT(DISTINCT o.lo_orderkey) AS num_orders,
    SUM(o.order_revenue) AS total_revenue,
    SUM(o.order_supplycost) AS total_supplycost,
    SUM(o.order_quantity) AS total_quantity,
    AVG(o.order_avg_discount) AS avg_discount
FROM order_summary o
JOIN supplier s
    ON o.lo_suppkey = s.s_suppkey
WHERE s.s_nation = 'UNITED STATES'
GROUP BY s.s_region, o.lo_orderdate
HAVING SUM(o.order_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 100

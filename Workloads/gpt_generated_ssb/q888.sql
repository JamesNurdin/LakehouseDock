WITH order_metrics AS (
    SELECT
        lo_suppkey,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_quantity,
        lo_shipmode,
        (lo_revenue - lo_supplycost) AS profit
    FROM lineorder
)
SELECT
    s.s_region,
    s.s_nation,
    s.s_city,
    SUM(om.lo_revenue) AS total_revenue,
    SUM(om.lo_supplycost) AS total_supplycost,
    SUM(om.profit) AS total_profit,
    AVG(om.lo_discount) AS avg_discount,
    COUNT(*) AS order_count,
    AVG(om.lo_quantity) AS avg_quantity
FROM order_metrics om
JOIN supplier s
    ON om.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, s.s_nation, s.s_city
ORDER BY total_profit DESC
LIMIT 10

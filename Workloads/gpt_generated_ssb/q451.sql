WITH order_profit AS (
    SELECT
        lo_suppkey,
        lo_shipmode,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_revenue - lo_supplycost AS profit
    FROM lineorder
    WHERE lo_discount > 0
)
SELECT
    su.s_region,
    su.s_nation,
    op.lo_shipmode,
    SUM(op.lo_revenue) AS total_revenue,
    SUM(op.profit) AS total_profit,
    AVG(op.lo_discount) AS avg_discount
FROM order_profit op
JOIN supplier su
    ON op.lo_suppkey = su.s_suppkey
GROUP BY su.s_region, su.s_nation, op.lo_shipmode
ORDER BY total_revenue DESC
LIMIT 10

WITH high_priority_orders AS (
    SELECT
        lo_suppkey,
        lo_orderkey,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_shipmode
    FROM lineorder
    WHERE lo_orderpriority IN ('1-URGENT', '2-HIGH')
)
SELECT
    supplier.s_region,
    high_priority_orders.lo_shipmode,
    SUM(high_priority_orders.lo_revenue) AS total_revenue,
    SUM(high_priority_orders.lo_supplycost) AS total_supply_cost,
    AVG(high_priority_orders.lo_discount) AS avg_discount,
    COUNT(DISTINCT high_priority_orders.lo_orderkey) AS distinct_orders
FROM high_priority_orders
JOIN supplier
    ON high_priority_orders.lo_suppkey = supplier.s_suppkey
GROUP BY supplier.s_region, high_priority_orders.lo_shipmode
ORDER BY total_revenue DESC

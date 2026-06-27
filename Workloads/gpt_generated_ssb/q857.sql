WITH filtered_lineorder AS (
    SELECT
        lo_orderkey,
        lo_suppkey,
        lo_revenue,
        lo_discount,
        lo_quantity,
        lo_extendedprice,
        lo_supplycost,
        lo_orderpriority,
        lo_shipmode
    FROM lineorder
    WHERE lo_shipmode = 'AIR'
)
SELECT
    s.s_region,
    s.s_nation,
    COUNT(DISTINCT filtered_lineorder.lo_orderkey) AS order_count,
    SUM(filtered_lineorder.lo_revenue) AS total_revenue,
    AVG(filtered_lineorder.lo_discount) AS avg_discount,
    SUM(filtered_lineorder.lo_supplycost) AS total_supply_cost,
    SUM(filtered_lineorder.lo_extendedprice) AS total_extended_price,
    SUM(filtered_lineorder.lo_quantity) AS total_quantity
FROM filtered_lineorder
JOIN supplier s
    ON filtered_lineorder.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, s.s_nation
HAVING SUM(filtered_lineorder.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 10

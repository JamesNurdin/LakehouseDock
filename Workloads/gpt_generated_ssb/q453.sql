WITH filtered_lo AS (
    SELECT
        lo_orderkey,
        lo_linenumber,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_orderpriority,
        lo_shippriority,
        lo_quantity,
        lo_extendedprice,
        lo_ordertotalprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        lo_commitdate,
        lo_shipmode
    FROM lineorder
    WHERE lo_quantity > 30
      AND lo_discount < 5
)
SELECT
    s.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    COUNT(*) AS order_count
FROM filtered_lo lo
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, p.p_category
ORDER BY total_profit DESC
LIMIT 10

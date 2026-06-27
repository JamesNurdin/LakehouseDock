WITH lineorder_part_supplier AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_orderdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        p.p_category,
        p.p_brand1,
        s.s_nation,
        s.s_region
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
)
SELECT
    p_category,
    s_region,
    SUM(lo_extendedprice) AS total_extended_price,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_extendedprice - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM lineorder_part_supplier
WHERE lo_shipmode = 'AIR'
GROUP BY p_category, s_region
HAVING SUM(lo_extendedprice - lo_supplycost) > 1000000
ORDER BY total_profit DESC
LIMIT 10

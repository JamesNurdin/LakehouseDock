WITH order_supplier AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_orderpriority,
        lo.lo_shippriority,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_commitdate,
        lo.lo_shipmode,
        s.s_name,
        s.s_address,
        s.s_city,
        s.s_nation,
        s.s_region,
        s.s_phone,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE s.s_region = 'AMERICA'
)
SELECT
    s_region,
    s_nation,
    lo_shipmode,
    SUM(lo_quantity)            AS total_quantity,
    SUM(lo_extendedprice)       AS total_extendedprice,
    SUM(lo_revenue)             AS total_revenue,
    SUM(profit)                 AS total_profit,
    AVG(lo_discount)            AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM order_supplier
GROUP BY s_region, s_nation, lo_shipmode
ORDER BY total_revenue DESC
LIMIT 10

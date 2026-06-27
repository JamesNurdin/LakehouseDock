-- Revenue and profit analysis by customer region, supplier region and market segment
WITH lo_customer_supplier AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_orderdate,
        lo.lo_orderpriority,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_commitdate,
        lo.lo_shipmode,
        c.c_custkey,
        c.c_name,
        c.c_city,
        c.c_nation,
        c.c_region,
        c.c_mktsegment,
        s.s_suppkey,
        s.s_name,
        s.s_city,
        s.s_nation,
        s.s_region
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_orderpriority IN ('1-URGENT', '2-HIGH')
)
SELECT
    c_region,
    s_region,
    c_mktsegment,
    COUNT(DISTINCT lo_orderkey) AS num_orders,
    SUM(lo_extendedprice) AS total_extended_price,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_extendedprice - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    SUM(lo_quantity) AS total_quantity
FROM lo_customer_supplier
GROUP BY
    c_region,
    s_region,
    c_mktsegment
HAVING SUM(lo_extendedprice) > 1000000
ORDER BY total_revenue DESC
LIMIT 20

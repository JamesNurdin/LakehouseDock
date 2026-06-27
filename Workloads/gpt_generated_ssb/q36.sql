WITH lo_cust_supp AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_orderdate,
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        s.s_nation AS s_nation,
        s.s_region AS s_region
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
)
SELECT
    c_region,
    c_mktsegment,
    s_nation,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supply_cost,
    SUM(lo_revenue) - SUM(lo_supplycost) AS profit,
    COUNT(*) AS order_count
FROM lo_cust_supp
WHERE lo_quantity > 0
GROUP BY
    c_region,
    c_mktsegment,
    s_nation
ORDER BY total_revenue DESC
LIMIT 20

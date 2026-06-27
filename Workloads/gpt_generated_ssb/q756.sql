/* Revenue and profit analysis by product category and supplier region */
WITH lo_part_supp AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_shipmode,
        lo.lo_orderpriority,
        p.p_category,
        p.p_brand1,
        s.s_region,
        s.s_nation,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_quantity > 10
)
SELECT
    p_category,
    s_region,
    COUNT(DISTINCT lo_orderkey) AS num_orders,
    SUM(lo_quantity) AS total_quantity,
    SUM(lo_revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    SUM(lo_extendedprice) AS total_extendedprice
FROM lo_part_supp
GROUP BY p_category, s_region
ORDER BY total_revenue DESC
LIMIT 100

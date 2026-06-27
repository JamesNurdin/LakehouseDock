WITH lo_details AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderpriority,
        lo.lo_shipmode,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        c.c_region AS c_region,
        c.c_nation AS c_nation,
        c.c_mktsegment AS c_mktsegment,
        p.p_category AS p_category,
        p.p_brand1 AS p_brand1,
        p.p_size AS p_size,
        s.s_region AS s_region,
        s.s_nation AS s_nation,
        (lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS profit
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_orderpriority IN ('1-URGENT', '2-HIGH')
      AND p.p_size > 20
      AND c.c_mktsegment = 'AUTOMOBILE'
)
SELECT
    s_region,
    p_category,
    c_nation,
    SUM(lo_revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    COUNT(*) AS order_count,
    AVG(lo_discount) AS avg_discount
FROM lo_details
GROUP BY s_region, p_category, c_nation
ORDER BY total_revenue DESC
LIMIT 100

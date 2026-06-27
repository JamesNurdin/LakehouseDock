WITH line_profit AS (
    SELECT
        c.c_region AS region,
        c.c_nation AS nation,
        p.p_brand1 AS brand,
        lo.lo_orderpriority AS order_priority,
        lo.lo_quantity AS quantity,
        lo.lo_extendedprice AS extendedprice,
        lo.lo_supplycost AS supplycost,
        lo.lo_tax AS tax,
        lo.lo_discount AS discount,
        (lo.lo_extendedprice - lo.lo_supplycost - lo.lo_tax) AS profit
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE c.c_mktsegment = 'BUILDING'
      AND lo.lo_shipmode = 'AIR'
)
SELECT
    region,
    nation,
    brand,
    order_priority,
    SUM(quantity) AS total_quantity,
    SUM(extendedprice) AS total_extendedprice,
    SUM(supplycost) AS total_supplycost,
    SUM(tax) AS total_tax,
    SUM(profit) AS total_profit,
    AVG(discount) AS avg_discount,
    COUNT(*) AS line_count
FROM line_profit
GROUP BY region, nation, brand, order_priority
ORDER BY total_profit DESC
LIMIT 20

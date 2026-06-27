WITH lo_with_net AS (
    SELECT
        lo.lo_custkey,
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_quantity,
        lo.lo_extendedprice * (1 - lo.lo_discount / 100.0) AS net_price
    FROM lineorder lo
)
SELECT
    c.c_region,
    c.c_nation,
    SUM(lo.net_price) AS total_net_price,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lo_with_net lo
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
WHERE c.c_mktsegment = 'AUTOMOBILE'
  AND lo.lo_quantity > 10
GROUP BY c.c_region, c.c_nation
ORDER BY total_net_price DESC
LIMIT 10

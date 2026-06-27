WITH lo_filtered AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_shipmode
    FROM lineorder
    WHERE lo_quantity > 0
      AND lo_discount BETWEEN 0 AND 5
      AND lo_shipmode IN ('AIR', 'RAIL')
),
joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        p.p_category,
        p.p_brand1,
        p.p_color
    FROM lo_filtered lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
)
SELECT
    c_region,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders,
    COUNT(DISTINCT c_nation) AS distinct_nations
FROM joined
GROUP BY c_region, p_category
HAVING SUM(lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 10

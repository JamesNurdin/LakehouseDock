WITH lo_cust_part AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_extendedprice,
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE c.c_region = 'AMERICA'
      AND lo.lo_shipmode = 'AIR'
)
SELECT
    c_region,
    c_nation,
    p_category,
    p_brand1,
    SUM(lo_revenue) AS total_revenue,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM lo_cust_part
GROUP BY GROUPING SETS (
    (c_region, p_category),
    (c_region, c_nation, p_category, p_brand1)
)
HAVING SUM(lo_revenue) > 0
ORDER BY total_revenue DESC
LIMIT 20

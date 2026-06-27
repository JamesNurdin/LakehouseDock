WITH lo_cust_supp AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        s.s_name,
        s.s_nation,
        s.s_region
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE c.c_mktsegment = 'AUTOMOBILE'
)
SELECT
    c_region,
    s_nation,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_quantity) AS total_quantity,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS distinct_orders
FROM lo_cust_supp
GROUP BY c_region, s_nation
ORDER BY total_revenue DESC
LIMIT 5

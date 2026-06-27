WITH filtered_orders AS (
    SELECT
        lo_orderdate,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        lo_quantity,
        lo_shipmode
    FROM lineorder
    WHERE lo_discount > 5
      AND lo_shipmode = 'AIR'
)
SELECT
    d.d_year,
    c.c_nation,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM filtered_orders lo
JOIN dim_date d ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#14'
  AND s.s_region = 'AMERICA'
GROUP BY d.d_year, c.c_nation, p.p_category
ORDER BY d.d_year, c.c_nation

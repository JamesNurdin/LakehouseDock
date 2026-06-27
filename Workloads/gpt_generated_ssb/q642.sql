SELECT
    od.d_year AS order_year,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    s.s_region AS supplier_region,
    SUM(lo.lo_quantity) AS total_quantity,
    SUM(lo.lo_extendedprice) AS total_extended_price,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_extendedprice - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    AVG(lo.lo_commitdate - lo.lo_orderdate) AS avg_commit_delay
FROM lineorder lo
JOIN dim_date od ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
JOIN dim_date cd ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE od.d_year = '1997'
  AND p.p_category = 'MFGR#12'
  AND lo.lo_commitdate >= lo.lo_orderdate
GROUP BY od.d_year, c.c_region, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 20

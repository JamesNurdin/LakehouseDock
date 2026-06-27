SELECT
    s.s_region AS supplier_region,
    od.d_year AS order_year,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    SUM(lo.lo_quantity) AS total_quantity
FROM lineorder lo
JOIN dim_date od
    ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#1'
  AND CAST(od.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY s.s_region, od.d_year
ORDER BY total_revenue DESC

SELECT
    d.d_year,
    c.c_region,
    p.p_category,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count,
    SUM(lo.lo_extendedprice) AS total_extended_price,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supplycost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN dim_date d
    ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
  AND c.c_region = 'ASIA'
  AND s.s_region = 'ASIA'
GROUP BY d.d_year, c.c_region, p.p_category
ORDER BY total_profit DESC
LIMIT 10

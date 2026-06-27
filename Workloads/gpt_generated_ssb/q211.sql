SELECT
    d.d_year AS order_year,
    s.s_region AS supplier_region,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN dim_date d
  ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY d.d_year, s.s_region, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 20

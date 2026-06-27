SELECT
    d.d_year AS order_year,
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    p.p_brand1 AS brand,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN dim_date d
  ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
WHERE d.d_year = '1995'
GROUP BY d.d_year, c.c_region, s.s_region, p.p_brand1
ORDER BY total_profit DESC
LIMIT 20

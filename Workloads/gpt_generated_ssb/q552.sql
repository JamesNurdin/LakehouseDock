SELECT
    d_order.d_year AS order_year,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    SUM(lo.lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo.lo_orderkey) AS num_orders
FROM lineorder lo
JOIN dim_date d_order
  ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
JOIN dim_date d_commit
  ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE d_order.d_year = '1995'
GROUP BY d_order.d_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 10

SELECT
    d_order.d_year AS order_year,
    c.c_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers,
    AVG(lo.lo_quantity) AS avg_quantity
FROM lineorder lo
JOIN dim_date d_order
  ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
JOIN dim_date d_commit
  ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE CAST(d_order.d_date AS date) BETWEEN DATE '1993-01-01' AND DATE '1997-12-31'
  AND lo.lo_discount BETWEEN 0 AND 5
GROUP BY d_order.d_year, c.c_region, p.p_category
HAVING SUM(lo.lo_revenue) > 1000000
ORDER BY total_revenue DESC
LIMIT 20

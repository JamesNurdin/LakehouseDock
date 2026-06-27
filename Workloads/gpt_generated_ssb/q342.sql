-- Total revenue, profit and other metrics by customer region, supplier region, part category and order year
SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    p.p_category AS part_category,
    d_order.d_year AS order_year,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    SUM(lo.lo_quantity) AS total_quantity,
    COUNT(DISTINCT lo.lo_custkey) AS distinct_customers,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
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
WHERE d_commit.d_year = '1997'
  AND lo.lo_orderpriority = '1-URGENT'
GROUP BY
    c.c_region,
    s.s_region,
    p.p_category,
    d_order.d_year
ORDER BY total_revenue DESC

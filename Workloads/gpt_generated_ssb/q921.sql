WITH orders_1995 AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_partkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity
    FROM lineorder lo
    JOIN dim_date d
      ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    WHERE d.d_year = '1995'
)
SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    p.p_category AS part_category,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount,
    COUNT(DISTINCT o.lo_orderkey) AS order_count
FROM orders_1995 o
JOIN customer c
  ON o.lo_custkey = c.c_custkey
JOIN supplier s
  ON o.lo_suppkey = s.s_suppkey
JOIN part p
  ON o.lo_partkey = p.p_partkey
GROUP BY c.c_region, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 50

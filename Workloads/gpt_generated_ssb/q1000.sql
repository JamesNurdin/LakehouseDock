WITH revenue_by_region_category AS (
  SELECT
    c.c_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS num_orders
  FROM lineorder lo
  JOIN customer c ON lo.lo_custkey = c.c_custkey
  JOIN part p ON lo.lo_partkey = p.p_partkey
  JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
  WHERE s.s_region = 'EUROPE'
  GROUP BY c.c_region, p.p_category
)
SELECT
  r.c_region,
  r.p_category,
  r.total_revenue,
  r.avg_discount,
  r.num_orders,
  RANK() OVER (PARTITION BY r.c_region ORDER BY r.total_revenue DESC) AS category_rank,
  SUM(r.total_revenue) OVER (
    PARTITION BY r.c_region
    ORDER BY r.total_revenue
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_revenue
FROM revenue_by_region_category r
ORDER BY r.c_region, category_rank
LIMIT 100

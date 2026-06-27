WITH agg AS (
  SELECT
    od.d_year AS order_year,
    s.s_region AS supplier_region,
    p.p_category AS part_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supplycost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
  FROM lineorder lo
  JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
  JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
  JOIN part p ON lo.lo_partkey = p.p_partkey
  WHERE od.d_year IN ('1995', '1996')
    AND lo.lo_discount > 5
  GROUP BY od.d_year, s.s_region, p.p_category
)
SELECT
  order_year,
  supplier_region,
  part_category,
  total_revenue,
  total_supplycost,
  total_profit,
  profit_rank
FROM (
  SELECT
    order_year,
    supplier_region,
    part_category,
    total_revenue,
    total_supplycost,
    total_profit,
    RANK() OVER (PARTITION BY order_year ORDER BY total_profit DESC) AS profit_rank
  FROM agg
) ranked
WHERE profit_rank <= 5
ORDER BY order_year, profit_rank

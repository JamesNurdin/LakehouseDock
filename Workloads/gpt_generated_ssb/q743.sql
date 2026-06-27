WITH revenue_by_cat AS (
  SELECT
    s.s_region,
    p.p_category,
    d.d_year,
    d.d_month,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS order_cnt,
    SUM(lo.lo_quantity) AS total_quantity
  FROM lineorder lo
  JOIN dim_date d
    ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
  JOIN part p
    ON lo.lo_partkey = p.p_partkey
  JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
  WHERE d.d_year = '1997'
  GROUP BY s.s_region, p.p_category, d.d_year, d.d_month
)
SELECT
  s_region,
  p_category,
  d_year,
  d_month,
  total_revenue,
  profit,
  avg_discount,
  order_cnt,
  total_quantity,
  ROW_NUMBER() OVER (PARTITION BY s_region ORDER BY profit DESC) AS region_category_profit_rank
FROM revenue_by_cat
ORDER BY s_region, region_category_profit_rank
LIMIT 200

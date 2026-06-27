WITH aggregated AS (
  SELECT
    dim_date.d_year,
    supplier.s_region,
    part.p_brand1,
    sum(lineorder.lo_revenue) AS total_revenue,
    sum(lineorder.lo_supplycost) AS total_supplycost,
    sum(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit
  FROM lineorder
  JOIN dim_date
    ON cast(dim_date.d_datekey AS integer) = lineorder.lo_orderdate
  JOIN supplier
    ON lineorder.lo_suppkey = supplier.s_suppkey
  JOIN part
    ON lineorder.lo_partkey = part.p_partkey
  WHERE dim_date.d_year = '1997'
  GROUP BY dim_date.d_year, supplier.s_region, part.p_brand1
)
SELECT
  aggregated.d_year,
  aggregated.s_region,
  aggregated.p_brand1,
  aggregated.total_revenue,
  aggregated.total_supplycost,
  aggregated.total_profit,
  rank() OVER (PARTITION BY aggregated.d_year ORDER BY aggregated.total_profit DESC) AS profit_rank
FROM aggregated
WHERE aggregated.total_revenue > 1000000
ORDER BY aggregated.total_profit DESC
LIMIT 10

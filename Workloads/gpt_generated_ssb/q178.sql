SELECT
    c.c_region,
    d_order.d_year,
    SUM(lo.lo_revenue) AS total_revenue,
    COUNT(DISTINCT lo.lo_orderkey) AS num_orders,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN dim_date d_order
  ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
JOIN dim_date d_commit
  ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
WHERE c.c_nation = 'UNITED STATES'
  AND d_order.d_year BETWEEN '1992' AND '1997'
  AND d_commit.d_holidayfl = 'Y'
GROUP BY c.c_region, d_order.d_year
ORDER BY total_revenue DESC

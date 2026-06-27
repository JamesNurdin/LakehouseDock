SELECT
    od.d_year AS order_year,
    cd.d_year AS commit_year,
    SUM(lo.lo_revenue) AS total_revenue,
    COUNT(*) AS order_count
FROM lineorder lo
JOIN dim_date od
  ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
JOIN dim_date cd
  ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
GROUP BY od.d_year, cd.d_year
ORDER BY od.d_year, cd.d_year

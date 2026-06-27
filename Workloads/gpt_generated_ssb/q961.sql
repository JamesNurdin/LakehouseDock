SELECT
    c.c_region,
    od.d_year,
    od.d_month,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_custkey) AS distinct_customers,
    MIN(od.d_date) AS earliest_order_date,
    MAX(cd.d_date) AS latest_commit_date
FROM lineorder lo
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN dim_date od
  ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
JOIN dim_date cd
  ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
WHERE od.d_date BETWEEN '1995-01-01' AND '1995-12-31'
  AND c.c_mktsegment = 'AUTOMOBILE'
GROUP BY c.c_region, od.d_year, od.d_month
ORDER BY total_revenue DESC

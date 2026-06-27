WITH lo_filtered AS (
    SELECT
        lo_orderkey,
        lo_revenue,
        lo_discount,
        lo_shipmode,
        lo_orderdate,
        lo_commitdate
    FROM lineorder
    WHERE lo_shipmode IN ('AIR', 'RAIL')
)
SELECT
    od.d_year AS order_year,
    cd.d_month AS commit_month,
    SUM(lf.lo_revenue) AS total_revenue,
    AVG(lf.lo_discount) AS avg_discount,
    COUNT(DISTINCT lf.lo_orderkey) AS order_cnt
FROM lo_filtered lf
JOIN dim_date od
  ON lf.lo_orderdate = CAST(od.d_datekey AS INTEGER)
JOIN dim_date cd
  ON lf.lo_commitdate = CAST(cd.d_datekey AS INTEGER)
WHERE od.d_year = '1995'
GROUP BY od.d_year, cd.d_month
ORDER BY total_revenue DESC
LIMIT 10

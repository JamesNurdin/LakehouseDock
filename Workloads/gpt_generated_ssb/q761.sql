SELECT
    d_order.d_year AS order_year,
    d_order.d_month AS order_month,
    lo.lo_shipmode,
    SUM(lo.lo_revenue) AS total_revenue,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM lineorder lo
JOIN dim_date d_order
    ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
JOIN dim_date d_commit
    ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
WHERE d_order.d_year = '1997'
  AND d_commit.d_date > '1997-12-31'
GROUP BY d_order.d_year, d_order.d_month, lo.lo_shipmode
ORDER BY d_order.d_year, d_order.d_month, lo.lo_shipmode

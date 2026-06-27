SELECT
    od.d_year AS order_year,
    od.d_month AS order_month,
    lo.lo_shipmode,
    lo.lo_orderpriority,
    SUM(lo.lo_revenue) AS total_revenue,
    COUNT(*) AS order_count
FROM lineorder lo
JOIN dim_date od
    ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
WHERE od.d_date BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY od.d_year, od.d_month, lo.lo_shipmode, lo.lo_orderpriority
ORDER BY od.d_year, od.d_month, lo.lo_shipmode, lo.lo_orderpriority

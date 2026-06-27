SELECT
    od.d_year AS order_year,
    od.d_month AS order_month,
    SUM(lineorder.lo_extendedprice) AS total_extended_price,
    SUM(lineorder.lo_revenue) AS total_revenue,
    SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
    AVG(lineorder.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(od.d_date AS date), CAST(cd.d_date AS date))) AS avg_lead_time_days,
    COUNT(DISTINCT lineorder.lo_orderkey) AS distinct_orders,
    COUNT(*) AS lineitem_count
FROM lineorder
JOIN dim_date AS od
    ON CAST(od.d_datekey AS integer) = lineorder.lo_orderdate
JOIN dim_date AS cd
    ON CAST(cd.d_datekey AS integer) = lineorder.lo_commitdate
WHERE od.d_year = '1998'
  AND lineorder.lo_discount > 5
GROUP BY od.d_year, od.d_month
ORDER BY od.d_year, od.d_month

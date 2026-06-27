SELECT
    customer.c_region,
    part.p_category,
    order_date_dim.d_year,
    sum(lineorder.lo_revenue) AS total_revenue,
    sum(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
    avg(lineorder.lo_discount) AS avg_discount,
    avg(date_diff('day', date(order_date_dim.d_date), date(commit_date_dim.d_date))) AS avg_lead_time
FROM lineorder
JOIN customer ON lineorder.lo_custkey = customer.c_custkey
JOIN part ON lineorder.lo_partkey = part.p_partkey
JOIN supplier ON lineorder.lo_suppkey = supplier.s_suppkey
JOIN dim_date AS order_date_dim ON lineorder.lo_orderdate = cast(order_date_dim.d_datekey AS integer)
JOIN dim_date AS commit_date_dim ON lineorder.lo_commitdate = cast(commit_date_dim.d_datekey AS integer)
WHERE order_date_dim.d_year = '1994'
GROUP BY
    customer.c_region,
    part.p_category,
    order_date_dim.d_year
ORDER BY total_revenue DESC
LIMIT 10

SELECT
    customer.c_region,
    supplier.s_region,
    part.p_category,
    order_date_dim.d_year,
    order_date_dim.d_month,
    sum(lineorder.lo_revenue) AS total_revenue,
    sum(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
    count(distinct lineorder.lo_orderkey) AS order_count,
    avg(CAST(commit_date_dim.d_daynuminyear AS INTEGER) - CAST(order_date_dim.d_daynuminyear AS INTEGER)) AS avg_lead_time_days
FROM lineorder
JOIN dim_date AS order_date_dim
    ON CAST(order_date_dim.d_datekey AS INTEGER) = lineorder.lo_orderdate
JOIN dim_date AS commit_date_dim
    ON CAST(commit_date_dim.d_datekey AS INTEGER) = lineorder.lo_commitdate
JOIN customer
    ON lineorder.lo_custkey = customer.c_custkey
JOIN part
    ON lineorder.lo_partkey = part.p_partkey
JOIN supplier
    ON lineorder.lo_suppkey = supplier.s_suppkey
WHERE order_date_dim.d_year = '1995'
GROUP BY
    customer.c_region,
    supplier.s_region,
    part.p_category,
    order_date_dim.d_year,
    order_date_dim.d_month
ORDER BY total_revenue DESC

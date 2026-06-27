SELECT
    part.p_category,
    part.p_brand1,
    od.d_year,
    SUM(lineorder.lo_revenue) AS total_revenue,
    AVG(lineorder.lo_discount) AS avg_discount,
    AVG(lineorder.lo_commitdate - lineorder.lo_orderdate) AS avg_days_to_commit,
    COUNT(DISTINCT lineorder.lo_orderkey) AS order_count
FROM lineorder
JOIN dim_date AS od
    ON lineorder.lo_orderdate = CAST(od.d_datekey AS integer)
JOIN part
    ON lineorder.lo_partkey = part.p_partkey
WHERE od.d_year = '1995'
GROUP BY
    part.p_category,
    part.p_brand1,
    od.d_year
ORDER BY total_revenue DESC

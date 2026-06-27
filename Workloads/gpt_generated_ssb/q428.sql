SELECT
    c.c_region,
    od.d_year,
    sum(lo.lo_revenue) AS total_revenue,
    sum(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    avg(lo.lo_discount) AS avg_discount,
    sum(CASE WHEN cd.d_holidayfl = 'Y' THEN 1 ELSE 0 END) AS holiday_order_count
FROM lineorder lo
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN dim_date od
    ON cast(lo.lo_orderdate AS varchar) = od.d_datekey
JOIN dim_date cd
    ON cast(lo.lo_commitdate AS varchar) = cd.d_datekey
GROUP BY c.c_region, od.d_year
ORDER BY total_revenue DESC

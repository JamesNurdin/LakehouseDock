WITH dim_date_int AS (
    SELECT
        CAST(d_datekey AS integer) AS d_datekey_int,
        d_year
    FROM dim_date
)
SELECT
    c.c_region,
    d.d_year,
    sum(lo.lo_revenue) AS total_revenue,
    sum(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    avg(lo.lo_discount) AS avg_discount,
    count(distinct lo.lo_orderkey) AS num_orders
FROM lineorder lo
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN dim_date_int d
    ON lo.lo_orderdate = d.d_datekey_int
WHERE d.d_year IN ('1995', '1996', '1997')
GROUP BY c.c_region, d.d_year
HAVING sum(lo.lo_revenue) > 1000000
ORDER BY total_revenue DESC

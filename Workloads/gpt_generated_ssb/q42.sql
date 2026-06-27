WITH order_metrics AS (
    SELECT
        c.c_region AS c_region,
        od.d_year AS d_year,
        lo.lo_revenue AS lo_revenue,
        lo.lo_supplycost AS lo_supplycost,
        lo.lo_discount AS lo_discount,
        date_diff(
            'day',
            date_parse(od.d_date, '%Y-%m-%d'),
            date_parse(cd.d_date, '%Y-%m-%d')
        ) AS shipping_delay_days
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE od.d_year = '1997'
)
SELECT
    c_region,
    d_year,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue) - SUM(lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    AVG(shipping_delay_days) AS avg_shipping_delay_days
FROM order_metrics
GROUP BY c_region, d_year
ORDER BY total_revenue DESC

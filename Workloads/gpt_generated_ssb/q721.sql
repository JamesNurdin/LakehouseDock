WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_revenue,
        d_order.d_year AS order_year,
        d_order.d_date AS order_date,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
    WHERE d_order.d_year = '1995'
)
SELECT
    c.c_region,
    od.order_year,
    AVG(date_diff('day', date(od.commit_date), date(od.order_date))) AS avg_lead_days,
    SUM(od.lo_revenue) AS total_revenue,
    COUNT(DISTINCT od.lo_orderkey) AS num_orders
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
GROUP BY c.c_region, od.order_year
ORDER BY total_revenue DESC
LIMIT 10

SELECT
    d_order.d_year AS order_year,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(d_order.d_date AS DATE), CAST(d_commit.d_date AS DATE))) AS avg_lead_days
FROM lineorder lo
JOIN dim_date d_order
    ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
JOIN dim_date d_commit
    ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
WHERE d_order.d_year = '1995'
GROUP BY d_order.d_year, p.p_category
ORDER BY total_revenue DESC

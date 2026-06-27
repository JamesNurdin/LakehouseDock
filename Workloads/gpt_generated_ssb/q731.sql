SELECT
    p.p_category,
    p.p_brand1,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount,
    AVG(date_diff('day', date_parse(d_order.d_date, '%Y-%m-%d'), date_parse(d_commit.d_date, '%Y-%m-%d'))) AS avg_days_to_commit,
    COUNT(*) AS order_count
FROM lineorder lo
JOIN dim_date d_order
    ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
JOIN dim_date d_commit
    ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
WHERE d_order.d_year = '1995'
GROUP BY p.p_category, p.p_brand1
ORDER BY total_revenue DESC
LIMIT 10

SELECT
    p.p_category,
    d_order.d_year AS order_year,
    d_commit.d_year AS commit_year,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_quantity) AS total_quantity,
    SUM(lo.lo_revenue) / SUM(lo.lo_quantity) AS revenue_per_quantity
FROM lineorder lo
JOIN dim_date d_order
    ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
JOIN dim_date d_commit
    ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
WHERE d_order.d_year = '1997'
  AND d_commit.d_year = '1998'
GROUP BY p.p_category, d_order.d_year, d_commit.d_year
ORDER BY total_revenue DESC

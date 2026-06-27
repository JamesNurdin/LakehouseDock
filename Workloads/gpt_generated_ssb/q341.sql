WITH order_dim AS (
    SELECT
        d_datekey,
        d_date,
        d_year
    FROM dim_date
    WHERE CAST(d_date AS DATE) >= DATE '1995-01-01'
      AND CAST(d_date AS DATE) < DATE '1996-01-01'
),
commit_dim AS (
    SELECT
        d_datekey,
        d_date
    FROM dim_date
)
SELECT
    order_dim.d_year AS order_year,
    supplier.s_region,
    part.p_category,
    AVG(date_diff('day', CAST(order_dim.d_date AS DATE), CAST(commit_dim.d_date AS DATE))) AS avg_days_to_commit,
    SUM(lineorder.lo_revenue) AS total_revenue,
    COUNT(DISTINCT lineorder.lo_orderkey) AS order_cnt
FROM lineorder
JOIN order_dim
    ON lineorder.lo_orderdate = CAST(order_dim.d_datekey AS INTEGER)
JOIN commit_dim
    ON lineorder.lo_commitdate = CAST(commit_dim.d_datekey AS INTEGER)
JOIN supplier
    ON lineorder.lo_suppkey = supplier.s_suppkey
JOIN part
    ON lineorder.lo_partkey = part.p_partkey
WHERE supplier.s_region = 'ASIA'
GROUP BY order_dim.d_year, supplier.s_region, part.p_category
ORDER BY order_dim.d_year

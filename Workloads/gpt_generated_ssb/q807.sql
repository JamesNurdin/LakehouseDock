WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
)
SELECT
    order_year,
    supplier_region,
    AVG(date_diff('day', CAST(order_date AS DATE), CAST(commit_date AS DATE))) AS avg_lead_time_days,
    COUNT(*) AS order_count
FROM order_commit
GROUP BY order_year, supplier_region
ORDER BY order_year, avg_lead_time_days DESC

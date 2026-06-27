WITH lineorder_enhanced AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_orderdate,
        lo.lo_commitdate,
        c.c_region,
        od.d_year,
        od.d_month,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS INTEGER)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE od.d_year = '1997'
      AND c.c_region = 'ASIA'
)
SELECT
    c_region,
    d_year,
    d_month,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_orderkey) AS order_count,
    AVG(date_diff('day', CAST(order_date AS DATE), CAST(commit_date AS DATE))) AS avg_days_to_commit
FROM lineorder_enhanced
GROUP BY c_region, d_year, d_month
ORDER BY total_revenue DESC
LIMIT 10

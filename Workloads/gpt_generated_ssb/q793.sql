WITH order_dim AS (
    SELECT
        d_datekey,
        d_year,
        d_month,
        CAST(d_date AS date) AS d_date_val
    FROM dim_date
),
commit_dim AS (
    SELECT
        d_datekey,
        CAST(d_date AS date) AS d_date_val
    FROM dim_date
)
SELECT
    od.d_year AS order_year,
    od.d_month AS order_month,
    lo.lo_orderpriority,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count,
    AVG(date_diff('day', od.d_date_val, cd.d_date_val)) AS avg_days_to_commit
FROM lineorder lo
JOIN order_dim od
    ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
JOIN commit_dim cd
    ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
WHERE CAST(od.d_year AS integer) BETWEEN 1993 AND 1995
    AND lo.lo_shipmode = 'AIR'
GROUP BY od.d_year, od.d_month, lo.lo_orderpriority
ORDER BY total_revenue DESC
LIMIT 100

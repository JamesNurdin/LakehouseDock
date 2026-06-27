WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
    WHERE od.d_year = '1995'
)
SELECT
    s.s_region,
    od.order_year,
    p.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_supplycost) AS total_supplycost,
    AVG(od.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(od.order_date AS DATE), CAST(od.commit_date AS DATE))) AS avg_days_to_commit,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
FROM order_dates od
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN customer c
    ON od.lo_custkey = c.c_custkey
WHERE p.p_category = 'MFGR#12'
  AND c.c_region = 'ASIA'
GROUP BY s.s_region, od.order_year, p.p_category
ORDER BY total_revenue DESC
LIMIT 10

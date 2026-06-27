WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_quantity,
        c.c_region,
        p.p_category,
        s.s_region,
        od.d_year AS order_year,
        CAST(od.d_date AS DATE) AS order_date,
        cd.d_year AS commit_year,
        CAST(cd.d_date AS DATE) AS commit_date
    FROM lineorder lo
    JOIN dim_date od
      ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
      ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    JOIN customer c
      ON lo.lo_custkey = c.c_custkey
    JOIN part p
      ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
      ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
)
SELECT
    c_region,
    order_year,
    AVG(date_diff('day', order_date, commit_date)) AS avg_days_to_commit,
    SUM(lo_extendedprice) AS total_extendedprice,
    SUM(lo_revenue) AS total_revenue,
    COUNT(DISTINCT lo_orderkey) AS order_count
FROM order_commit
WHERE p_category = 'MFGR#1'
  AND s_region = 'ASIA'
GROUP BY c_region, order_year
ORDER BY total_revenue DESC

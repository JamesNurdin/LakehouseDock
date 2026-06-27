WITH order_commit AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_shipmode,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    WHERE CAST(od.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
)
SELECT
    oc.order_year,
    c.c_region,
    p.p_category,
    COUNT(*) AS order_count,
    SUM(oc.lo_extendedprice * (100 - oc.lo_discount) / 100) AS total_revenue,
    AVG(date_diff('day', CAST(oc.order_date AS date), CAST(oc.commit_date AS date))) AS avg_lead_time_days
FROM order_commit oc
JOIN customer c ON oc.lo_custkey = c.c_custkey
JOIN part p ON oc.lo_partkey = p.p_partkey
JOIN supplier s ON oc.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#12'
  AND oc.lo_shipmode = 'AIR'
GROUP BY oc.order_year, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 50

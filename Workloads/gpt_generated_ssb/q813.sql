WITH order_commit_dates AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        od.d_date AS order_date,
        od.d_year AS order_year,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
)
SELECT
    c.c_region,
    c.c_nation,
    oc.order_year,
    p.p_category,
    SUM(oc.lo_revenue) AS total_revenue,
    SUM(oc.lo_revenue - oc.lo_supplycost - oc.lo_tax) AS total_profit,
    AVG(date_diff('day', CAST(oc.order_date AS DATE), CAST(oc.commit_date AS DATE))) AS avg_lead_time_days,
    AVG(oc.lo_discount) AS avg_discount,
    COUNT(*) AS order_count
FROM order_commit_dates oc
JOIN customer c
    ON oc.lo_custkey = c.c_custkey
JOIN part p
    ON oc.lo_partkey = p.p_partkey
JOIN supplier s
    ON oc.lo_suppkey = s.s_suppkey
WHERE oc.order_year = '1997'
GROUP BY
    c.c_region,
    c.c_nation,
    oc.order_year,
    p.p_category
ORDER BY total_revenue DESC
LIMIT 10

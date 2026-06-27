WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        CAST(od.d_date AS date) AS order_date,
        CAST(cd.d_date AS date) AS commit_date,
        od.d_year AS order_year
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    WHERE od.d_year = '1998'
)
SELECT
    s.s_region,
    p.p_category,
    COUNT(*) AS order_count,
    SUM(oi.lo_extendedprice * (1 - oi.lo_discount / 100.0)) AS revenue,
    SUM(oi.lo_extendedprice * (1 - oi.lo_discount / 100.0) - oi.lo_supplycost) AS profit,
    AVG(date_diff('day', oi.order_date, oi.commit_date)) AS avg_days_to_commit
FROM order_info oi
JOIN part p
    ON oi.lo_partkey = p.p_partkey
JOIN supplier s
    ON oi.lo_suppkey = s.s_suppkey
GROUP BY s.s_region, p.p_category
ORDER BY profit DESC
LIMIT 10

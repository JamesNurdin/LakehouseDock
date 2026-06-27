WITH lo_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        c.c_region AS c_region,
        s.s_region AS s_region,
        p.p_category AS p_category,
        od.d_year AS d_year,
        od.d_month AS d_month,
        od.d_date AS order_date,
        cd.d_date AS commit_date,
        date_diff('day', CAST(od.d_date AS date), CAST(cd.d_date AS date)) AS days_to_commit
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN dim_date od ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
)
SELECT
    c_region,
    s_region,
    d_year,
    p_category,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_supplycost) AS total_supplycost,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    AVG(days_to_commit) AS avg_days_to_commit
FROM lo_dates
WHERE d_year = '1995'
GROUP BY c_region, s_region, d_year, p_category
ORDER BY total_profit DESC
LIMIT 20

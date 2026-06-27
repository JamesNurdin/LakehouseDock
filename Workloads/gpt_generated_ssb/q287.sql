WITH lo_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
)
SELECT
    lo_dates.order_year,
    c.c_region,
    p.p_category,
    s.s_region,
    SUM(lo_dates.lo_revenue) AS total_revenue,
    SUM(lo_dates.lo_revenue - lo_dates.lo_supplycost) AS total_profit,
    AVG(lo_dates.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(lo_dates.order_date AS date), CAST(lo_dates.commit_date AS date))) AS avg_commit_delay_days,
    COUNT(DISTINCT lo_dates.lo_orderkey) AS order_count
FROM lo_dates
JOIN customer c
    ON lo_dates.lo_custkey = c.c_custkey
JOIN part p
    ON lo_dates.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo_dates.lo_suppkey = s.s_suppkey
WHERE CAST(lo_dates.order_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    AND p.p_category = 'MFGR#12'
GROUP BY lo_dates.order_year, c.c_region, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 10

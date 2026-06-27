WITH filtered_dates AS (
    SELECT
        d_datekey,
        d_year
    FROM dim_date
    WHERE d_year = '1995'
)
SELECT
    d.d_year,
    c.c_region,
    s.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN filtered_dates d
    ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE c.c_region = 'EUROPE'
GROUP BY
    d.d_year,
    c.c_region,
    s.s_region,
    p.p_category
ORDER BY total_revenue DESC
LIMIT 20

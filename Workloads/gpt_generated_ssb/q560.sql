WITH lo_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_discount,
        d_ord.d_year AS order_year,
        d_com.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_ord
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_ord.d_datekey
    JOIN dim_date d_com
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_com.d_datekey
)
SELECT
    lo_dates.order_year,
    c.c_region,
    s.s_region,
    p.p_category,
    SUM(lo_dates.lo_revenue) AS total_revenue,
    AVG(lo_dates.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_dates.lo_orderkey) AS num_orders
FROM lo_dates
JOIN customer c
    ON lo_dates.lo_custkey = c.c_custkey
JOIN part p
    ON lo_dates.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo_dates.lo_suppkey = s.s_suppkey
WHERE lo_dates.order_year = '1995'
  AND c.c_region = 'AMERICA'
GROUP BY lo_dates.order_year, c.c_region, s.s_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 100

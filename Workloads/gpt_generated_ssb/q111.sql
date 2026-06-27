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
        od.d_year AS order_year,
        CAST(od.d_date AS DATE) AS order_date,
        cd.d_year AS commit_year,
        CAST(cd.d_date AS DATE) AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
)
SELECT
    c.c_region,
    lo_dates.order_year,
    p.p_category,
    SUM(lo_dates.lo_revenue) AS total_revenue,
    SUM(lo_dates.lo_revenue - lo_dates.lo_supplycost) AS total_profit,
    AVG(lo_dates.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_dates.lo_orderkey) AS num_orders
FROM lo_dates
JOIN customer c
    ON lo_dates.lo_custkey = c.c_custkey
JOIN part p
    ON lo_dates.lo_partkey = p.p_partkey
WHERE lo_dates.order_date BETWEEN DATE '1993-01-01' AND DATE '1997-12-31'
  AND p.p_category = 'MFGR#1'
GROUP BY c.c_region, lo_dates.order_year, p.p_category
ORDER BY total_revenue DESC
LIMIT 100

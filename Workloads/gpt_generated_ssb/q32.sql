WITH order_dates AS (
    SELECT
        d_datekey,
        d_date,
        d_year
    FROM dim_date
    WHERE CAST(d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
commit_dates AS (
    SELECT
        d_datekey,
        d_date,
        d_year
    FROM dim_date
    WHERE CAST(d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    od.d_year AS order_year,
    cd.d_year AS commit_year,
    c.c_region AS region,
    p.p_category AS category,
    SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS revenue,
    COUNT(*) AS order_count
FROM lineorder lo
JOIN order_dates od
    ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
JOIN commit_dates cd
    ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
WHERE p.p_category = 'MFGR#12'
  AND lo.lo_shipmode = 'AIR'
GROUP BY od.d_year, cd.d_year, c.c_region, p.p_category
ORDER BY revenue DESC
LIMIT 10

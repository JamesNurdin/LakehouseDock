WITH order_dim AS (
    SELECT
        CAST(d_datekey AS integer) AS d_datekey_int,
        d_year,
        d_month,
        d_date
    FROM dim_date
)
SELECT
    d.d_year AS year,
    c.c_region AS region,
    p.p_category AS category,
    s.s_nation AS supplier_nation,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN order_dim d
    ON lo.lo_orderdate = d.d_datekey_int
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
WHERE d.d_year = '1995'
  AND p.p_category = 'MFGR#1'
  AND lo.lo_shipmode = 'AIR'
  AND s.s_nation = 'UNITED STATES'
  AND c.c_region = 'AMERICA'
GROUP BY d.d_year, c.c_region, p.p_category, s.s_nation
ORDER BY total_revenue DESC
LIMIT 100

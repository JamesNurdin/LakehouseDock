WITH order_year AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    WHERE d.d_year = '1995'
)
SELECT
    oy.d_year,
    s.s_region,
    SUM(oy.lo_revenue) AS total_revenue,
    SUM(oy.lo_revenue - oy.lo_supplycost - oy.lo_tax) AS total_profit,
    COUNT(DISTINCT oy.lo_orderkey) AS order_count
FROM order_year oy
JOIN supplier s
    ON oy.lo_suppkey = s.s_suppkey
JOIN part p
    ON oy.lo_partkey = p.p_partkey
WHERE p.p_category = 'MFGR#12'
  AND oy.lo_discount > 5
  AND oy.lo_shipmode = 'AIR'
GROUP BY oy.d_year, s.s_region
ORDER BY total_revenue DESC

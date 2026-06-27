WITH line_revenue AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        (lo.lo_extendedprice * (100 - lo.lo_discount) / 100.0) AS line_revenue,
        (lo.lo_extendedprice * (100 - lo.lo_discount) / 100.0 - lo.lo_supplycost) AS line_profit
    FROM lineorder lo
)
SELECT
    d.d_year,
    s.s_region,
    p.p_category,
    SUM(lr.line_revenue) AS revenue,
    SUM(lr.line_profit) AS profit
FROM line_revenue lr
JOIN dim_date d
    ON CAST(lr.lo_orderdate AS VARCHAR) = d.d_datekey
JOIN part p
    ON lr.lo_partkey = p.p_partkey
JOIN supplier s
    ON lr.lo_suppkey = s.s_suppkey
JOIN customer c
    ON lr.lo_custkey = c.c_custkey
WHERE p.p_category = 'MFGR#12'
  AND s.s_region = 'ASIA'
  AND c.c_mktsegment = 'AUTOMOBILE'
  AND d.d_year = '1997'
GROUP BY d.d_year, s.s_region, p.p_category
ORDER BY d.d_year, s.s_region

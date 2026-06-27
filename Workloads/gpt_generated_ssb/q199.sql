WITH lo_base AS (
    SELECT
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_orderdate,
        lo.lo_suppkey,
        lo.lo_partkey
    FROM lineorder lo
)
SELECT
    d.d_year,
    s.s_region,
    p.p_brand1,
    SUM(lo_base.lo_revenue - lo_base.lo_supplycost) AS total_profit,
    SUM(lo_base.lo_quantity) AS total_quantity,
    AVG(lo_base.lo_discount) AS avg_discount
FROM lo_base
JOIN dim_date d
    ON CAST(lo_base.lo_orderdate AS varchar) = d.d_datekey
JOIN supplier s
    ON lo_base.lo_suppkey = s.s_suppkey
JOIN part p
    ON lo_base.lo_partkey = p.p_partkey
WHERE d.d_year = '1997'
  AND p.p_category = 'MFGR#1'
GROUP BY d.d_year, s.s_region, p.p_brand1
ORDER BY total_profit DESC

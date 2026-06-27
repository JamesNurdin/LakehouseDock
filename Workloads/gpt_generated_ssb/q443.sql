WITH filtered_orders AS (
    SELECT
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_discount,
        od.d_year,
        s.s_region
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE od.d_year = '1997'
      AND p.p_category = 'MFGR#12'
      AND c.c_mktsegment = 'AUTOMOBILE'
)
SELECT
    f.s_region,
    f.d_year,
    SUM(f.lo_revenue) AS total_revenue,
    SUM(f.lo_revenue - f.lo_supplycost - f.lo_tax) AS total_profit,
    AVG(f.lo_discount) AS avg_discount
FROM filtered_orders f
GROUP BY f.s_region, f.d_year
ORDER BY total_revenue DESC

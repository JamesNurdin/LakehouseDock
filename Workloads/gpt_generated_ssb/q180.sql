WITH joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        c.c_region,
        dd.d_year,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date dd
        ON CAST(lo.lo_orderdate AS varchar) = dd.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
)
SELECT
    joined.c_region,
    joined.d_year,
    SUM(joined.lo_revenue) AS total_revenue,
    SUM(joined.lo_revenue - joined.lo_supplycost) AS total_profit
FROM joined
WHERE joined.p_category = 'MFGR#12'
  AND joined.s_region = 'ASIA'
  AND joined.d_year BETWEEN '1992' AND '1997'
GROUP BY joined.c_region, joined.d_year
ORDER BY total_revenue DESC

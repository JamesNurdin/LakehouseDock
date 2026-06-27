WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_partkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        od.d_year
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE od.d_year = '1995'
      AND p.p_category = 'MFGR#12'
)
SELECT
    fo.d_year,
    c.c_region,
    s.s_region,
    SUM(fo.lo_revenue) AS total_revenue,
    SUM(fo.lo_supplycost) AS total_supply_cost,
    SUM(fo.lo_revenue - fo.lo_supplycost) AS total_profit
FROM filtered_orders fo
JOIN customer c
    ON fo.lo_custkey = c.c_custkey
JOIN supplier s
    ON fo.lo_suppkey = s.s_suppkey
GROUP BY fo.d_year, c.c_region, s.s_region
ORDER BY total_profit DESC
LIMIT 10

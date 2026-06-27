WITH filtered_orders AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity
    FROM lineorder lo
    JOIN dim_date d ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year = '1997'
      AND p.p_mfgr = 'MFGR#1'
      AND c.c_mktsegment = 'AUTOMOBILE'
)
SELECT
    d.d_year,
    s.s_region,
    SUM(f.lo_revenue) AS total_revenue,
    SUM(f.lo_supplycost) AS total_supply_cost,
    SUM(f.lo_revenue) - SUM(f.lo_supplycost) AS total_profit,
    SUM(f.lo_quantity) AS total_quantity
FROM filtered_orders f
JOIN dim_date d ON f.lo_orderdate = CAST(d.d_datekey AS INTEGER)
JOIN supplier s ON f.lo_suppkey = s.s_suppkey
GROUP BY d.d_year, s.s_region
ORDER BY total_revenue DESC

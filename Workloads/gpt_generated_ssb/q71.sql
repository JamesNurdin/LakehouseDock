WITH supplier_yearly AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_region,
        d.d_year,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS profit,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
      AND p.p_category = 'MFGR#12'
    GROUP BY s.s_suppkey, s.s_name, s.s_region, d.d_year
)
SELECT
    sy.s_region,
    sy.d_year,
    sy.s_name,
    sy.total_revenue,
    sy.profit,
    sy.avg_discount,
    RANK() OVER (PARTITION BY sy.d_year ORDER BY sy.profit DESC) AS profit_rank
FROM supplier_yearly sy
ORDER BY sy.d_year, profit_rank
LIMIT 10

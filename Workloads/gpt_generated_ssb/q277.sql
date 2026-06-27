WITH profit_by_year_region AS (
    SELECT
        d.d_year,
        s.s_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE p.p_category = 'MFGR#12'
      AND c.c_mktsegment = 'AUTOMOBILE'
      AND CAST(d.d_date AS DATE) BETWEEN DATE '1992-01-01' AND DATE '1997-12-31'
    GROUP BY d.d_year, s.s_region
)
SELECT
    d_year,
    s_region,
    total_revenue,
    total_supply_cost,
    profit,
    RANK() OVER (PARTITION BY d_year ORDER BY profit DESC) AS profit_rank
FROM profit_by_year_region
ORDER BY d_year, profit_rank
LIMIT 20

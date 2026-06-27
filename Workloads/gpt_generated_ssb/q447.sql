WITH orders_filtered AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        d.d_year,
        c.c_region
    FROM lineorder lo
    JOIN dim_date d ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_date >= '1995-01-01' AND d.d_date <= '1995-12-31'
      AND p.p_category = 'MFGR#1'
      AND s.s_region = 'ASIA'
),
profit_by_region AS (
    SELECT
        d_year,
        c_region,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_revenue - lo_supplycost) AS total_profit
    FROM orders_filtered
    GROUP BY d_year, c_region
)
SELECT
    d_year,
    c_region,
    total_revenue,
    total_supplycost,
    total_profit,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM profit_by_region
ORDER BY d_year, profit_rank

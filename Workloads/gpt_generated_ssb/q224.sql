WITH filtered AS (
    SELECT
        d.d_year,
        s.s_region,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_orderkey
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
      AND p.p_category = 'MFGR#12'
),
agg AS (
    SELECT
        d_year,
        s_region,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_revenue) - SUM(lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS num_orders
    FROM filtered
    GROUP BY d_year, s_region
),
ranked AS (
    SELECT
        d_year,
        s_region,
        total_revenue,
        total_profit,
        avg_discount,
        num_orders,
        RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
    FROM agg
)
SELECT
    d_year,
    s_region,
    total_revenue,
    total_profit,
    avg_discount,
    num_orders,
    profit_rank
FROM ranked
WHERE profit_rank <= 5
ORDER BY d_year, profit_rank

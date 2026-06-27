WITH orders_filtered AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        c.c_region,
        d.d_month,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE d.d_year = '1995'
      AND p.p_mfgr = 'MFGR#1'
),
region_month_agg AS (
    SELECT
        c_region,
        d_month,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit
    FROM orders_filtered
    GROUP BY c_region, d_month
),
ranked_region_month AS (
    SELECT
        c_region,
        d_month,
        total_revenue,
        total_profit,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM region_month_agg
)
SELECT
    c_region,
    d_month,
    total_revenue,
    total_profit,
    revenue_rank
FROM ranked_region_month
WHERE revenue_rank <= 5
ORDER BY revenue_rank

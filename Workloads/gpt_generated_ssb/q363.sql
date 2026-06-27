WITH filtered_orders AS (
    SELECT
        lo.lo_orderdate,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE p.p_category = 'MFGR#1'
),
joined AS (
    SELECT
        d.d_year,
        c.c_region,
        s.s_name,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_revenue - lo.lo_supplycost AS profit
    FROM filtered_orders lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d.d_date AS date) BETWEEN DATE '1993-01-01' AND DATE '1993-12-31'
),
aggregated AS (
    SELECT
        d_year,
        c_region,
        s_name,
        SUM(profit) AS total_profit
    FROM joined
    GROUP BY d_year, c_region, s_name
),
ranked AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (PARTITION BY a.d_year, a.c_region ORDER BY a.total_profit DESC) AS profit_rank
    FROM aggregated a
)
SELECT
    d_year,
    c_region,
    s_name,
    total_profit,
    profit_rank
FROM ranked
WHERE profit_rank <= 3
ORDER BY d_year, c_region, profit_rank

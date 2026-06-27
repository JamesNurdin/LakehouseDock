WITH agg AS (
    SELECT
        c.c_region AS region,
        d_order.d_year AS year,
        p.p_category AS category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost * lo.lo_quantity) AS total_supply_cost,
        SUM(lo.lo_revenue - lo.lo_supplycost * lo.lo_quantity) AS total_profit,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d_order.d_year = '1995'
      AND c.c_region = 'ASIA'
      AND p.p_mfgr = 'MFGR#1'
    GROUP BY c.c_region, d_order.d_year, p.p_category
)
SELECT
    region,
    year,
    category,
    total_revenue,
    total_profit,
    total_quantity,
    avg_discount,
    RANK() OVER (PARTITION BY region ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY region, revenue_rank

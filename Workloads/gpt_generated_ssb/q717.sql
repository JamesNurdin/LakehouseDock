WITH agg AS (
    SELECT
        d.d_year,
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year = '1995'
    GROUP BY d.d_year, c.c_region, p.p_category
)
SELECT
    d_year,
    c_region,
    p_category,
    total_revenue,
    total_supply_cost,
    total_profit,
    avg_discount,
    order_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY d_year, revenue_rank
LIMIT 20

WITH sales_by_region_category AS (
    SELECT
        d.d_year,
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS num_orders
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year = '1995'
    GROUP BY d.d_year, c.c_region, p.p_category
)
SELECT
    s.d_year,
    s.c_region,
    s.p_category,
    s.total_revenue,
    s.total_profit,
    s.avg_discount,
    s.num_orders,
    RANK() OVER (PARTITION BY s.c_region ORDER BY s.total_revenue DESC) AS revenue_rank_in_region
FROM sales_by_region_category s
ORDER BY s.total_revenue DESC
LIMIT 20

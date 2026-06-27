WITH revenue_by_category AS (
    SELECT
        d.d_year,
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supplycost,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS num_orders
    FROM lineorder lo
    JOIN dim_date d ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year BETWEEN '1995' AND '1997'
    GROUP BY d.d_year, c.c_region, p.p_category
)
SELECT
    rbc.d_year,
    rbc.c_region,
    rbc.p_category,
    rbc.total_revenue,
    rbc.total_supplycost,
    rbc.total_revenue - rbc.total_supplycost AS total_profit,
    rbc.total_quantity,
    rbc.avg_discount,
    rbc.num_orders,
    RANK() OVER (PARTITION BY rbc.d_year, rbc.c_region ORDER BY rbc.total_revenue DESC) AS revenue_rank
FROM revenue_by_category rbc
ORDER BY rbc.d_year, rbc.c_region, revenue_rank

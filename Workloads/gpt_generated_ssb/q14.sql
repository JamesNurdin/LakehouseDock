WITH revenue_by_category AS (
    SELECT
        d.d_year,
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date d ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year BETWEEN '1995' AND '1997'
    GROUP BY d.d_year, c.c_region, p.p_category
)
SELECT
    d_year,
    c_region,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY d_year, c_region ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_by_category
WHERE total_revenue > 0
ORDER BY d_year, c_region, revenue_rank
LIMIT 50

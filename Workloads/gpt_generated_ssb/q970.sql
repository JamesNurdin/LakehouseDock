WITH region_category_rev AS (
    SELECT
        c.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date d ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE d.d_date BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY c.c_region, p.p_category
)
SELECT
    r.c_region,
    r.p_category,
    r.total_revenue,
    r.total_quantity,
    r.avg_discount,
    RANK() OVER (PARTITION BY r.c_region ORDER BY r.total_revenue DESC) AS revenue_rank
FROM region_category_rev r
ORDER BY r.c_region, revenue_rank
LIMIT 20

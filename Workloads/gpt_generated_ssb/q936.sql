WITH revenue_by_category AS (
    SELECT
        d.d_year,
        cu.c_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
    JOIN customer cu
        ON lo.lo_custkey = cu.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    GROUP BY d.d_year, cu.c_region, p.p_category
)
SELECT
    r.d_year,
    r.c_region,
    r.p_category,
    r.total_revenue,
    r.total_profit,
    r.avg_discount,
    r.order_cnt,
    RANK() OVER (PARTITION BY r.d_year, r.c_region ORDER BY r.total_revenue DESC) AS revenue_rank
FROM revenue_by_category r
ORDER BY r.d_year, r.c_region, revenue_rank

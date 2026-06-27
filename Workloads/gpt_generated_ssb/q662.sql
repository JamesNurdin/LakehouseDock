WITH revenue_by_region_year_category AS (
    SELECT
        c.c_region,
        d.d_year,
        p.p_category,
        SUM(lo.lo_extendedprice * (1 - lo.lo_discount / 100.0)) AS revenue,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN dim_date d ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(d.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY c.c_region, d.d_year, p.p_category
)
SELECT
    r.c_region,
    r.d_year,
    r.p_category,
    r.revenue,
    r.avg_discount,
    r.order_cnt,
    r.revenue / total_rev.total_revenue * 100 AS revenue_pct_of_year
FROM revenue_by_region_year_category r
JOIN (
    SELECT d_year, SUM(revenue) AS total_revenue
    FROM revenue_by_region_year_category
    GROUP BY d_year
) total_rev
ON r.d_year = total_rev.d_year
ORDER BY r.revenue DESC
LIMIT 50

WITH revenue_by_region_year_category AS (
    SELECT
        c.c_region,
        od.d_year,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        AVG(date_diff('day', CAST(od.d_date AS DATE), CAST(cd.d_date AS DATE))) AS avg_lead_time
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE od.d_year = '1997'
    GROUP BY c.c_region, od.d_year, p.p_category
)
SELECT
    r.c_region,
    r.d_year,
    r.p_category,
    r.total_revenue,
    r.total_quantity,
    r.avg_discount,
    r.avg_lead_time,
    SUM(r.total_revenue) OVER (PARTITION BY r.c_region ORDER BY r.d_year) AS cumulative_revenue_by_region
FROM revenue_by_region_year_category r
ORDER BY r.total_revenue DESC
LIMIT 20

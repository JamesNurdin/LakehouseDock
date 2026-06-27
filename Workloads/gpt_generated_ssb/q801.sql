WITH aggregated AS (
    SELECT
        s.s_region,
        p.p_category,
        od.d_year,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        SUM(lo.lo_quantity) AS total_quantity
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
    GROUP BY s.s_region, p.p_category, od.d_year
), ranked AS (
    SELECT
        a.s_region,
        a.p_category,
        a.total_revenue,
        a.total_profit,
        a.avg_discount,
        a.total_quantity,
        ROW_NUMBER() OVER (PARTITION BY a.s_region ORDER BY a.total_revenue DESC) AS region_category_rank
    FROM aggregated a
)
SELECT
    r.s_region,
    r.p_category,
    r.total_revenue,
    r.total_profit,
    r.avg_discount,
    r.total_quantity,
    r.region_category_rank
FROM ranked r
WHERE r.region_category_rank <= 5
ORDER BY r.s_region, r.region_category_rank

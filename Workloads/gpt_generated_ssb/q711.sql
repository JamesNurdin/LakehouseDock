WITH aggregated AS (
    SELECT
        od.d_year AS order_year,
        p.p_category,
        s.s_region AS supplier_region,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year BETWEEN '1995' AND '1997'
    GROUP BY od.d_year, p.p_category, s.s_region
)
SELECT
    order_year,
    p_category,
    supplier_region,
    total_revenue,
    total_profit,
    avg_discount,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY order_year, revenue_rank

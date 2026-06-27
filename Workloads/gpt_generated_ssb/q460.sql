WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        d.d_year,
        d.d_month,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date cd ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    WHERE cd.d_year = d.d_year
),
aggregated AS (
    SELECT
        od.d_year,
        od.d_month,
        od.p_category,
        od.s_region,
        SUM(od.lo_revenue) AS total_revenue,
        SUM(od.lo_extendedprice * od.lo_discount / 100.0) AS total_discount_amount,
        AVG(od.lo_discount) AS avg_discount_percent,
        COUNT(DISTINCT od.lo_orderkey) AS distinct_orders
    FROM order_data od
    GROUP BY od.d_year, od.d_month, od.p_category, od.s_region
)
SELECT
    a.d_year AS order_year,
    a.d_month AS order_month,
    a.p_category,
    a.s_region,
    a.total_revenue,
    a.total_discount_amount,
    a.avg_discount_percent,
    a.distinct_orders,
    SUM(a.total_revenue) OVER (
        PARTITION BY a.s_region, a.p_category
        ORDER BY a.d_year, a.d_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue_by_region_category
FROM aggregated a
ORDER BY a.d_year, a.d_month, a.p_category, a.s_region

WITH aggregated AS (
    SELECT
        d.d_year,
        c.c_region AS cust_region,
        p.p_category,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        SUM(lo.lo_quantity) AS total_quantity,
        COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year IN ('1997', '1998')
    GROUP BY d.d_year, c.c_region, p.p_category
)
SELECT
    d_year,
    cust_region,
    p_category,
    total_revenue,
    total_profit,
    total_quantity,
    distinct_orders,
    LAG(total_revenue) OVER (PARTITION BY cust_region, p_category ORDER BY d_year) AS prev_year_revenue,
    CASE
        WHEN LAG(total_revenue) OVER (PARTITION BY cust_region, p_category ORDER BY d_year) = 0 THEN NULL
        ELSE (total_revenue - LAG(total_revenue) OVER (PARTITION BY cust_region, p_category ORDER BY d_year))
             / LAG(total_revenue) OVER (PARTITION BY cust_region, p_category ORDER BY d_year) * 100
    END AS revenue_yoy_pct
FROM aggregated
ORDER BY d_year, cust_region, p_category

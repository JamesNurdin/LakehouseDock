WITH revenue_by_region_year AS (
    SELECT
        dd.d_year AS order_year,
        c.c_region AS cust_region,
        s.s_region AS supp_region,
        SUM(lo.lo_revenue) AS revenue
    FROM lineorder lo
    JOIN dim_date dd ON CAST(lo.lo_orderdate AS varchar) = dd.d_datekey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE dd.d_year IN ('1993', '1994', '1995')
    GROUP BY dd.d_year, c.c_region, s.s_region
),
ranked_regions AS (
    SELECT
        order_year,
        cust_region,
        supp_region,
        revenue,
        ROW_NUMBER() OVER (PARTITION BY order_year ORDER BY revenue DESC) AS rn
    FROM revenue_by_region_year
)
SELECT
    order_year,
    cust_region,
    supp_region,
    revenue
FROM ranked_regions
WHERE rn <= 5
ORDER BY order_year, revenue DESC

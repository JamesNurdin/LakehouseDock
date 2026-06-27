WITH revenue_by_category AS (
    SELECT
        dim_date.d_year,
        customer.c_region,
        part.p_category,
        SUM(lineorder.lo_revenue) AS total_revenue
    FROM lineorder
    JOIN dim_date
        ON lineorder.lo_orderdate = CAST(dim_date.d_datekey AS integer)
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    WHERE CAST(dim_date.d_date AS date) BETWEEN DATE '1992-01-01' AND DATE '1997-12-31'
    GROUP BY dim_date.d_year, customer.c_region, part.p_category
),
ranked AS (
    SELECT
        d_year,
        c_region,
        p_category,
        total_revenue,
        ROW_NUMBER() OVER (PARTITION BY d_year, c_region ORDER BY total_revenue DESC) AS rn
    FROM revenue_by_category
)
SELECT
    d_year,
    c_region,
    p_category,
    total_revenue
FROM ranked
WHERE rn <= 3
ORDER BY d_year, c_region, total_revenue DESC

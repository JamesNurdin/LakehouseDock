WITH monthly_sales AS (
    SELECT
        supplier.s_region AS supplier_region,
        part.p_category AS part_category,
        dim_order.d_year AS order_year,
        dim_order.d_month AS order_month,
        dim_order.d_yearmonthnum AS year_month_num,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_quantity) AS total_quantity,
        COUNT(DISTINCT customer.c_custkey) AS distinct_customers,
        AVG(
            CAST(dim_commit.d_daynuminyear AS integer) - CAST(dim_order.d_daynuminyear AS integer)
        ) AS avg_days_to_commit
    FROM lineorder
    JOIN dim_date AS dim_order
        ON CAST(dim_order.d_datekey AS integer) = lineorder.lo_orderdate
    JOIN dim_date AS dim_commit
        ON CAST(dim_commit.d_datekey AS integer) = lineorder.lo_commitdate
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    WHERE CAST(dim_order.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY
        supplier.s_region,
        part.p_category,
        dim_order.d_year,
        dim_order.d_month,
        dim_order.d_yearmonthnum
)
SELECT
    supplier_region,
    part_category,
    order_year,
    order_month,
    total_revenue,
    total_quantity,
    distinct_customers,
    avg_days_to_commit,
    AVG(total_revenue) OVER (
        PARTITION BY supplier_region, part_category
        ORDER BY year_month_num
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3month_revenue
FROM monthly_sales
ORDER BY supplier_region, part_category, year_month_num

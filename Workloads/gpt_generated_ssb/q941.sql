WITH revenue_by_group AS (
    SELECT
        dim_date.d_year,
        part.p_category,
        supplier.s_region,
        SUM(lineorder.lo_revenue) AS total_revenue,
        SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
        AVG(lineorder.lo_discount) AS avg_discount
    FROM lineorder
    JOIN dim_date
        ON lineorder.lo_orderdate = CAST(dim_date.d_datekey AS integer)
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE dim_date.d_year = '1995'
    GROUP BY dim_date.d_year, part.p_category, supplier.s_region
),
customer_revenue AS (
    SELECT
        dim_date.d_year,
        part.p_category,
        supplier.s_region,
        customer.c_custkey,
        customer.c_name,
        SUM(lineorder.lo_revenue) AS cust_revenue
    FROM lineorder
    JOIN dim_date
        ON lineorder.lo_orderdate = CAST(dim_date.d_datekey AS integer)
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    WHERE dim_date.d_year = '1995'
    GROUP BY dim_date.d_year, part.p_category, supplier.s_region, customer.c_custkey, customer.c_name
),
ranked_customers AS (
    SELECT
        cr.d_year,
        cr.p_category,
        cr.s_region,
        cr.c_custkey,
        cr.c_name,
        cr.cust_revenue,
        ROW_NUMBER() OVER (PARTITION BY cr.d_year, cr.p_category, cr.s_region ORDER BY cr.cust_revenue DESC) AS revenue_rank
    FROM customer_revenue cr
)
SELECT
    rg.d_year,
    rg.p_category,
    rg.s_region,
    rg.total_revenue,
    rg.total_profit,
    rg.avg_discount,
    rc.c_name AS top_customer_name,
    rc.cust_revenue AS top_customer_revenue,
    rc.revenue_rank
FROM revenue_by_group rg
LEFT JOIN ranked_customers rc
    ON rg.d_year = rc.d_year
    AND rg.p_category = rc.p_category
    AND rg.s_region = rc.s_region
    AND rc.revenue_rank = 1
ORDER BY rg.d_year, rg.p_category, rg.s_region

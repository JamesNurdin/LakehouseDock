WITH revenue_by_supplier_region AS (
    SELECT
        dim_date.d_year AS order_year,
        customer.c_region AS cust_region,
        part.p_category,
        supplier.s_suppkey,
        supplier.s_name,
        SUM(lineorder.lo_revenue) AS supplier_revenue,
        SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS supplier_profit
    FROM lineorder
    JOIN dim_date
        ON CAST(lineorder.lo_orderdate AS VARCHAR) = dim_date.d_datekey
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE dim_date.d_year = '1995'
    GROUP BY dim_date.d_year,
             customer.c_region,
             part.p_category,
             supplier.s_suppkey,
             supplier.s_name
),
ranked_suppliers AS (
    SELECT
        order_year,
        cust_region,
        p_category,
        s_suppkey,
        s_name,
        supplier_revenue,
        supplier_profit,
        ROW_NUMBER() OVER (PARTITION BY order_year, cust_region, p_category ORDER BY supplier_revenue DESC) AS revenue_rank
    FROM revenue_by_supplier_region
)
SELECT
    order_year,
    cust_region,
    p_category,
    s_name,
    supplier_revenue,
    supplier_profit
FROM ranked_suppliers
WHERE revenue_rank <= 2
ORDER BY order_year, cust_region, p_category, supplier_revenue DESC

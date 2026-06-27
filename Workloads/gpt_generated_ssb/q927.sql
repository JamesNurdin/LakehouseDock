WITH order_data AS (
    SELECT
        d.d_year,
        d.d_month,
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        p.p_category,
        lo.lo_revenue,
        lo.lo_extendedprice,
        lo.lo_quantity,
        lo.lo_discount
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year = '1995'
),
agg AS (
    SELECT
        d_year,
        d_month,
        customer_region,
        supplier_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_extendedprice) AS total_extendedprice,
        SUM(lo_quantity) AS total_quantity,
        AVG(lo_discount) AS avg_discount
    FROM order_data
    GROUP BY d_year, d_month, customer_region, supplier_region, p_category
)
SELECT
    d_year,
    d_month,
    customer_region,
    supplier_region,
    p_category,
    total_revenue,
    total_extendedprice,
    total_quantity,
    avg_discount,
    RANK() OVER (PARTITION BY d_year, d_month ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY d_year, d_month, revenue_rank

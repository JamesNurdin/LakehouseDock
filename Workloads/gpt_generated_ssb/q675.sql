WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_extendedprice,
        dim_order.d_year,
        part.p_category,
        supplier.s_region AS supplier_region,
        customer.c_custkey
    FROM lineorder lo
    JOIN dim_date dim_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = dim_order.d_datekey
    JOIN dim_date dim_commit
        ON CAST(lo.lo_commitdate AS VARCHAR) = dim_commit.d_datekey
    JOIN part
        ON lo.lo_partkey = part.p_partkey
    JOIN supplier
        ON lo.lo_suppkey = supplier.s_suppkey
    JOIN customer
        ON lo.lo_custkey = customer.c_custkey
    WHERE dim_order.d_date BETWEEN '1995-01-01' AND '1995-12-31'
),
aggregated AS (
    SELECT
        d_year,
        supplier_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders,
        COUNT(DISTINCT c_custkey) AS distinct_customers,
        AVG(lo_discount) AS avg_discount,
        SUM(lo_quantity) AS total_quantity,
        SUM(lo_extendedprice) AS total_extendedprice
    FROM order_details
    GROUP BY d_year, supplier_region, p_category
),
ranked AS (
    SELECT
        d_year,
        supplier_region,
        p_category,
        total_revenue,
        total_profit,
        distinct_orders,
        distinct_customers,
        avg_discount,
        total_quantity,
        total_extendedprice,
        ROW_NUMBER() OVER (PARTITION BY d_year, supplier_region ORDER BY total_revenue DESC) AS revenue_rank
    FROM aggregated
)
SELECT
    d_year,
    supplier_region,
    p_category,
    total_revenue,
    total_profit,
    distinct_orders,
    distinct_customers,
    avg_discount,
    total_quantity,
    total_extendedprice,
    revenue_rank
FROM ranked
WHERE revenue_rank <= 5
ORDER BY d_year, supplier_region, revenue_rank

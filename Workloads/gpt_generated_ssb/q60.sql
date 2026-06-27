WITH base AS (
    SELECT
        CAST(order_date.d_date AS DATE) AS order_date,
        order_date.d_year AS order_year,
        customer.c_region AS cust_region,
        part.p_category AS part_category,
        lineorder.lo_revenue AS revenue,
        lineorder.lo_supplycost AS supply_cost,
        lineorder.lo_discount AS discount,
        lineorder.lo_orderkey AS order_key,
        lineorder.lo_suppkey AS supp_key
    FROM lineorder
    JOIN dim_date AS order_date
      ON lineorder.lo_orderdate = CAST(order_date.d_datekey AS INTEGER)
    JOIN dim_date AS commit_date
      ON lineorder.lo_commitdate = CAST(commit_date.d_datekey AS INTEGER)
    JOIN customer
      ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
      ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier
      ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE CAST(order_date.d_date AS DATE) BETWEEN DATE '1992-01-01' AND DATE '1997-12-31'
),
agg AS (
    SELECT
        order_year,
        cust_region,
        part_category,
        COUNT(DISTINCT order_key) AS num_orders,
        SUM(revenue) AS total_revenue,
        SUM(revenue - supply_cost) AS total_profit,
        AVG(discount) AS avg_discount,
        COUNT(DISTINCT supp_key) AS num_suppliers
    FROM base
    GROUP BY order_year, cust_region, part_category
),
ranked AS (
    SELECT
        order_year,
        cust_region,
        part_category,
        total_revenue,
        total_profit,
        avg_discount,
        num_orders,
        num_suppliers,
        ROW_NUMBER() OVER (PARTITION BY order_year, cust_region ORDER BY total_revenue DESC) AS revenue_rank
    FROM agg
)
SELECT
    order_year,
    cust_region,
    part_category,
    total_revenue,
    total_profit,
    avg_discount,
    num_orders,
    num_suppliers
FROM ranked
WHERE revenue_rank <= 3
ORDER BY order_year, cust_region, revenue_rank

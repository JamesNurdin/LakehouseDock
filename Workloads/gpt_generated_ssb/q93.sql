WITH order_join AS (
    SELECT
        od.d_year AS order_year,
        s.s_region AS supplier_region,
        p.p_category AS part_category,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_orderkey
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    WHERE od.d_year BETWEEN '1993' AND '1995'
),
category_agg AS (
    SELECT
        order_year,
        supplier_region,
        part_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_quantity) AS total_quantity,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders
    FROM order_join
    GROUP BY order_year, supplier_region, part_category
),
ranked_category AS (
    SELECT
        order_year,
        supplier_region,
        part_category,
        total_revenue,
        total_supplycost,
        total_quantity,
        avg_discount,
        distinct_orders,
        ROW_NUMBER() OVER (PARTITION BY order_year, supplier_region ORDER BY total_revenue DESC) AS category_rank
    FROM category_agg
)
SELECT
    order_year,
    supplier_region,
    part_category,
    total_revenue,
    total_supplycost,
    total_quantity,
    avg_discount,
    distinct_orders,
    category_rank
FROM ranked_category
WHERE category_rank <= 3
ORDER BY order_year, supplier_region, category_rank

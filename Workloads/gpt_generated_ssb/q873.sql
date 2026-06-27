WITH order_dates AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_extendedprice,
        lo_discount,
        lo_supplycost,
        lo_tax,
        lo_quantity,
        lo_revenue,
        d_year AS order_year,
        d_month AS order_month
    FROM lineorder
    JOIN dim_date
        ON lineorder.lo_orderdate = CAST(dim_date.d_datekey AS integer)
),
customer_regions AS (
    SELECT
        c_custkey,
        c_region,
        c_mktsegment
    FROM customer
),
part_categories AS (
    SELECT
        p_partkey,
        p_category,
        p_brand1
    FROM part
)
SELECT
    od.order_year,
    cr.c_region,
    pc.p_category,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS num_orders
FROM order_dates od
JOIN customer_regions cr
    ON od.lo_custkey = cr.c_custkey
JOIN part_categories pc
    ON od.lo_partkey = pc.p_partkey
GROUP BY od.order_year, cr.c_region, pc.p_category
ORDER BY od.order_year, cr.c_region, pc.p_category

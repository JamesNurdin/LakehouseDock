WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        dim_ord.d_year AS order_year,
        CAST(dim_ord.d_date AS date) AS order_date,
        dim_com.d_year AS commit_year,
        CAST(dim_com.d_date AS date) AS commit_date
    FROM lineorder lo
    JOIN dim_date dim_ord
        ON CAST(dim_ord.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date dim_com
        ON CAST(dim_com.d_datekey AS integer) = lo.lo_commitdate
)
SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    order_details.order_year,
    p.p_category,
    p.p_brand1,
    SUM(order_details.lo_revenue) AS total_revenue,
    SUM(order_details.lo_revenue - order_details.lo_supplycost) AS total_profit,
    AVG(order_details.lo_discount) AS avg_discount,
    COUNT(DISTINCT order_details.lo_orderkey) AS distinct_orders
FROM order_details
JOIN customer c
    ON order_details.lo_custkey = c.c_custkey
JOIN supplier s
    ON order_details.lo_suppkey = s.s_suppkey
JOIN part p
    ON order_details.lo_partkey = p.p_partkey
WHERE order_details.order_date >= DATE '1995-01-01'
  AND order_details.order_date < DATE '1996-01-01'
GROUP BY
    c.c_region,
    s.s_region,
    order_details.order_year,
    p.p_category,
    p.p_brand1
ORDER BY total_revenue DESC
LIMIT 20

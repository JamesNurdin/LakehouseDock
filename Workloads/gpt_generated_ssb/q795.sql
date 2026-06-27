WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d_ord.d_year AS order_year,
        d_ord.d_month AS order_month,
        d_ord.d_date AS order_date
    FROM lineorder AS lo
    JOIN dim_date AS d_ord
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_ord.d_datekey
    WHERE d_ord.d_year = '1995'
)
SELECT
    order_info.order_year,
    order_info.order_month,
    cust.c_region,
    supp.s_region,
    SUM(order_info.lo_revenue) AS total_revenue,
    SUM(order_info.lo_revenue - order_info.lo_supplycost - order_info.lo_tax) AS total_profit,
    AVG(order_info.lo_discount) AS avg_discount,
    COUNT(DISTINCT order_info.lo_orderkey) AS distinct_orders
FROM order_info
JOIN customer AS cust
    ON order_info.lo_custkey = cust.c_custkey
JOIN supplier AS supp
    ON order_info.lo_suppkey = supp.s_suppkey
GROUP BY
    order_info.order_year,
    order_info.order_month,
    cust.c_region,
    supp.s_region
ORDER BY total_revenue DESC
LIMIT 10

WITH order_agg AS (
    SELECT
        CAST(od.d_year AS integer) AS order_year,
        od.d_month AS order_month,
        lo_shipmode,
        sum(lo_revenue) AS total_revenue,
        sum(lo_extendedprice) AS total_extendedprice,
        avg(lo_discount) AS avg_discount,
        count(DISTINCT lo_orderkey) AS distinct_orders
    FROM lineorder
    JOIN dim_date AS od
        ON CAST(od.d_datekey AS integer) = lineorder.lo_orderdate
    GROUP BY CAST(od.d_year AS integer), od.d_month, lo_shipmode
)
SELECT
    order_year,
    order_month,
    lo_shipmode,
    total_revenue,
    total_extendedprice,
    avg_discount,
    distinct_orders,
    row_number() OVER (PARTITION BY order_year, order_month ORDER BY total_revenue DESC) AS revenue_rank
FROM order_agg
WHERE order_year = 1995
ORDER BY order_year, order_month, revenue_rank
LIMIT 50

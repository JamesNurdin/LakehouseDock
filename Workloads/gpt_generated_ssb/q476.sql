WITH order_details AS (
    SELECT
        lo_orderdate,
        lo_partkey,
        lo_suppkey,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        (lo_revenue - lo_supplycost) AS profit
    FROM lineorder
    WHERE lo_discount <= 5
)
SELECT
    order_date.d_year AS year,
    supplier.s_region AS region,
    part.p_category AS category,
    SUM(order_details.lo_revenue) AS total_revenue,
    SUM(order_details.profit) AS total_profit,
    AVG(order_details.lo_discount) AS avg_discount
FROM order_details
JOIN dim_date AS order_date
  ON CAST(order_details.lo_orderdate AS VARCHAR) = order_date.d_datekey
JOIN part
  ON order_details.lo_partkey = part.p_partkey
JOIN supplier
  ON order_details.lo_suppkey = supplier.s_suppkey
WHERE CAST(order_date.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY order_date.d_year, supplier.s_region, part.p_category
ORDER BY total_revenue DESC
LIMIT 20

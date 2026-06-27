WITH orders AS (
    SELECT
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_quantity,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        dim_date.d_year AS order_year
    FROM lineorder
    JOIN dim_date
      ON CAST(dim_date.d_datekey AS integer) = lineorder.lo_orderdate
    WHERE CAST(dim_date.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT
    orders.order_year,
    customer.c_mktsegment,
    supplier.s_region,
    part.p_category,
    SUM(orders.lo_revenue) AS total_revenue,
    SUM(orders.lo_supplycost) AS total_supplycost,
    SUM(orders.lo_revenue - orders.lo_supplycost) AS total_profit,
    AVG(orders.lo_discount) AS avg_discount,
    SUM(orders.lo_quantity) AS total_quantity
FROM orders
JOIN customer
  ON orders.lo_custkey = customer.c_custkey
JOIN part
  ON orders.lo_partkey = part.p_partkey
JOIN supplier
  ON orders.lo_suppkey = supplier.s_suppkey
GROUP BY
    orders.order_year,
    customer.c_mktsegment,
    supplier.s_region,
    part.p_category
ORDER BY total_revenue DESC
LIMIT 100

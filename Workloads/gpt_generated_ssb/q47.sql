WITH order_details AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_supplycost,
        lo_tax,
        lo_orderdate,
        lo_commitdate,
        (lo_revenue - lo_supplycost) AS profit
    FROM lineorder
)
SELECT
    dim_date.d_year,
    customer.c_region,
    part.p_category,
    supplier.s_nation,
    SUM(order_details.lo_revenue) AS total_revenue,
    SUM(order_details.profit) AS total_profit,
    COUNT(*) AS order_count
FROM order_details
JOIN dim_date
  ON CAST(dim_date.d_datekey AS INTEGER) = order_details.lo_orderdate
JOIN customer
  ON order_details.lo_custkey = customer.c_custkey
JOIN part
  ON order_details.lo_partkey = part.p_partkey
JOIN supplier
  ON order_details.lo_suppkey = supplier.s_suppkey
WHERE order_details.lo_discount > 5
  AND order_details.lo_quantity BETWEEN 10 AND 30
GROUP BY dim_date.d_year, customer.c_region, part.p_category, supplier.s_nation
ORDER BY total_revenue DESC
LIMIT 50

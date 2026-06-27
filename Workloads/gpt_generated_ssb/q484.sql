WITH dim_order AS (
    SELECT
        CAST(d_datekey AS integer) AS d_datekey_int,
        d_date,
        d_year
    FROM dim_date
)
SELECT
    dim_order.d_year AS order_year,
    supplier.s_region,
    part.p_category,
    SUM(lineorder.lo_revenue) AS total_revenue,
    SUM(lineorder.lo_revenue - lineorder.lo_supplycost) AS total_profit,
    AVG(lineorder.lo_discount) AS avg_discount
FROM lineorder
JOIN dim_order
    ON lineorder.lo_orderdate = dim_order.d_datekey_int
JOIN customer
    ON lineorder.lo_custkey = customer.c_custkey
JOIN part
    ON lineorder.lo_partkey = part.p_partkey
JOIN supplier
    ON lineorder.lo_suppkey = supplier.s_suppkey
WHERE dim_order.d_date BETWEEN '1997-01-01' AND '1997-12-31'
  AND lineorder.lo_orderpriority = '1-URGENT'
  AND lineorder.lo_shipmode = 'AIR'
GROUP BY dim_order.d_year, supplier.s_region, part.p_category
ORDER BY total_revenue DESC
LIMIT 10

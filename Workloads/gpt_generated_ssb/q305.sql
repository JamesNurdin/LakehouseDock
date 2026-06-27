WITH filtered_orders AS (
    SELECT
        lo_orderdate,
        lo_revenue,
        lo_quantity,
        lo_discount,
        lo_partkey,
        lo_suppkey
    FROM lineorder
)
SELECT
    dim_date.d_year,
    supplier.s_region,
    SUM(filtered_orders.lo_revenue) AS total_revenue,
    SUM(filtered_orders.lo_quantity) AS total_quantity,
    AVG(filtered_orders.lo_discount) AS avg_discount
FROM filtered_orders
JOIN dim_date
  ON filtered_orders.lo_orderdate = CAST(dim_date.d_datekey AS integer)
JOIN part
  ON filtered_orders.lo_partkey = part.p_partkey
JOIN supplier
  ON filtered_orders.lo_suppkey = supplier.s_suppkey
WHERE part.p_category = 'MFGR#12'
  AND CAST(dim_date.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
  AND supplier.s_region = 'ASIA'
GROUP BY dim_date.d_year, supplier.s_region
ORDER BY total_revenue DESC

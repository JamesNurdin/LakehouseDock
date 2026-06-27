WITH filtered_orders AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_suppkey,
        lo_partkey,
        lo_revenue,
        lo_supplycost,
        lo_discount,
        lo_orderdate
    FROM lineorder
    WHERE lo_orderdate IS NOT NULL
)
SELECT
    customer.c_region,
    supplier.s_nation,
    dim_date.d_year,
    SUM(filtered_orders.lo_revenue) AS total_revenue,
    SUM(filtered_orders.lo_revenue - filtered_orders.lo_supplycost) AS total_profit,
    AVG(filtered_orders.lo_discount) AS avg_discount
FROM filtered_orders
JOIN customer ON filtered_orders.lo_custkey = customer.c_custkey
JOIN supplier ON filtered_orders.lo_suppkey = supplier.s_suppkey
JOIN part ON filtered_orders.lo_partkey = part.p_partkey
JOIN dim_date ON CAST(dim_date.d_datekey AS INTEGER) = filtered_orders.lo_orderdate
WHERE part.p_category = 'MFGR#12'
  AND CAST(dim_date.d_date AS DATE) >= DATE '1995-01-01'
  AND CAST(dim_date.d_date AS DATE) < DATE '1996-01-01'
GROUP BY customer.c_region, supplier.s_nation, dim_date.d_year
ORDER BY total_revenue DESC

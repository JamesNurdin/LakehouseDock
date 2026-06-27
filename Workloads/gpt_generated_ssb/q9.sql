WITH lo_filtered AS (
    SELECT
        lo_orderdate,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_revenue,
        lo_supplycost,
        lo_quantity,
        lo_discount
    FROM lineorder
    WHERE lo_discount >= 0
)
SELECT
    dim_date.d_year,
    customer.c_region,
    supplier.s_region,
    part.p_category,
    SUM(lo_filtered.lo_revenue) AS total_revenue,
    SUM(lo_filtered.lo_supplycost) AS total_supply_cost,
    SUM(lo_filtered.lo_quantity) AS total_quantity,
    AVG(lo_filtered.lo_discount) AS avg_discount
FROM lo_filtered
JOIN dim_date
  ON CAST(lo_filtered.lo_orderdate AS VARCHAR) = dim_date.d_datekey
JOIN customer
  ON lo_filtered.lo_custkey = customer.c_custkey
JOIN part
  ON lo_filtered.lo_partkey = part.p_partkey
JOIN supplier
  ON lo_filtered.lo_suppkey = supplier.s_suppkey
WHERE dim_date.d_year = '1997'
  AND customer.c_region = 'ASIA'
  AND part.p_category = 'MFGR#12'
GROUP BY
    dim_date.d_year,
    customer.c_region,
    supplier.s_region,
    part.p_category
ORDER BY total_revenue DESC
LIMIT 10

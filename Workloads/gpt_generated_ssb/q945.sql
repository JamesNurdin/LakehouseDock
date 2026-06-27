/*
  Analytical query: total revenue, profit and other metrics per order year and supplier region
  for parts in category 'MFGR#1' and supplier region 'ASIA', limited to orders placed in 1995.
*/
WITH order_dim AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        od.d_year      AS order_year,
        od.d_date      AS order_date,
        cd.d_year      AS commit_year,
        cd.d_date      AS commit_date
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
)
SELECT
    od.order_year,
    s.s_region            AS supplier_region,
    p.p_category,
    SUM(od.lo_revenue)                         AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost)      AS total_profit,
    AVG(od.lo_discount)                        AS avg_discount,
    SUM(od.lo_quantity)                        AS total_quantity,
    COUNT(DISTINCT od.lo_orderkey)             AS distinct_orders
FROM order_dim od
JOIN part p
    ON od.lo_partkey = p.p_partkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE p.p_category = 'MFGR#1'
  AND s.s_region = 'ASIA'
  AND CAST(od.order_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY od.order_year, s.s_region, p.p_category
ORDER BY od.order_year, s.s_region

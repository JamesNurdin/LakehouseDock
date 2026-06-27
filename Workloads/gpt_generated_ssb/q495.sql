/*
  Analytical query for the SSB schema (Trino / Iceberg).
  It computes revenue, supply‑cost and profit by customer region and part category
  for the year 1995, then ranks the categories inside each region by total revenue.
*/
WITH aggregated AS (
    SELECT
        od.d_year               AS order_year,
        c.c_region              AS c_region,
        p.p_category            AS p_category,
        SUM(lo.lo_revenue)      AS total_revenue,
        SUM(lo.lo_supplycost)   AS total_supplycost,
        SUM(lo.lo_revenue) - SUM(lo.lo_supplycost) AS total_profit,
        AVG(lo.lo_discount)     AS avg_discount
    FROM lineorder lo
    -- Join to the order‑date dimension (order date is a surrogate integer key)
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    -- Join to the commit‑date dimension (required by the allowed join rules)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS INTEGER)
    -- Join to the remaining dimension tables using the permitted keys
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year = '1995'
    GROUP BY od.d_year, c.c_region, p.p_category
)
SELECT
    order_year,
    c_region,
    p_category,
    total_revenue,
    total_supplycost,
    total_profit,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY c_region ORDER BY total_revenue DESC) AS region_category_rank
FROM aggregated
WHERE total_revenue > 0
ORDER BY total_profit DESC
LIMIT 10

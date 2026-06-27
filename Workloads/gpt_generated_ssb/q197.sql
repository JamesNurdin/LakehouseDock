/*
  Revenue and discount analysis by supplier region and order year
  (covers the years 1997‑1998)
*/
WITH revenue_by_region_year AS (
    SELECT
        supplier.s_region AS supplier_region,
        od.d_year      AS order_year,
        SUM(lineorder.lo_revenue)   AS total_revenue,
        AVG(lineorder.lo_discount)  AS avg_discount,
        COUNT(*)                    AS order_count
    FROM lineorder
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    JOIN dim_date AS od
        ON CAST(lineorder.lo_orderdate AS varchar) = od.d_datekey
    WHERE od.d_year BETWEEN '1997' AND '1998'
    GROUP BY supplier.s_region, od.d_year
)
SELECT
    supplier_region,
    order_year,
    total_revenue,
    avg_discount,
    order_count,
    CAST(total_revenue AS double) / SUM(total_revenue) OVER (PARTITION BY order_year) AS revenue_share
FROM revenue_by_region_year
ORDER BY order_year, total_revenue DESC

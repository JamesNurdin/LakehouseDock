/*
   Top‑5 supplier regions by revenue for each order year (1992‑1997),
   together with the average number of days between the order date and the
   commit date.  The query joins the lineorder fact table to the dim_date
   dimension twice (once for the order date and once for the commit date) and
   to the supplier dimension.  It filters on the order date via dim_date.d_date,
   aggregates revenue and lead‑time, then ranks the regions per year.
*/
WITH order_commit AS (
    SELECT
        od.d_year                               AS order_year,
        s.s_region                              AS supplier_region,
        SUM(lo.lo_revenue)                      AS total_revenue,
        AVG(date_diff('day', CAST(od.d_date AS date), CAST(cd.d_date AS date)))
                                                AS avg_lead_days,
        COUNT(*)                                AS order_count
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
    JOIN dim_date cd
        ON CAST(lo.lo_commitdate AS varchar) = cd.d_datekey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(od.d_date AS date) >= DATE '1992-01-01'
      AND CAST(od.d_date AS date) <= DATE '1997-12-31'
    GROUP BY od.d_year, s.s_region
)
SELECT
    order_year,
    supplier_region,
    total_revenue,
    avg_lead_days,
    order_count,
    region_rank
FROM (
    SELECT
        order_year,
        supplier_region,
        total_revenue,
        avg_lead_days,
        order_count,
        ROW_NUMBER() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS region_rank
    FROM order_commit
) q
WHERE region_rank <= 5
ORDER BY order_year, region_rank

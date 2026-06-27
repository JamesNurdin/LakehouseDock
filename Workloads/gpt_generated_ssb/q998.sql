/*
  Revenue and year‑over‑year growth by part category and supplier region
  – joins lineorder to the date dimension for the order date,
    to supplier for region, and to part for category.
  – aggregates revenue per year, region and category, then uses a window
    function to compute the prior‑year revenue and YoY growth.
*/
WITH yearly_category_region AS (
    SELECT
        d_order.d_year AS order_year,
        s.s_region,
        p.p_category,
        SUM(lo.lo_revenue) AS revenue,
        COUNT(*) AS order_cnt
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d_order.d_year BETWEEN '1995' AND '1997'
      AND lo.lo_shipmode = 'AIR'
    GROUP BY d_order.d_year, s.s_region, p.p_category
)
SELECT
    order_year,
    s_region,
    p_category,
    revenue,
    order_cnt,
    LAG(revenue) OVER (PARTITION BY s_region, p_category ORDER BY order_year) AS prev_year_revenue,
    (revenue - LAG(revenue) OVER (PARTITION BY s_region, p_category ORDER BY order_year))
        / NULLIF(LAG(revenue) OVER (PARTITION BY s_region, p_category ORDER BY order_year), 0) AS yoy_growth
FROM yearly_category_region
ORDER BY s_region, p_category, order_year

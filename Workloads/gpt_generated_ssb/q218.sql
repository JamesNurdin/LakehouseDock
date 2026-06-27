WITH total_stats AS (
    SELECT d.d_year,
           s.s_region,
           SUM(lo.lo_revenue) AS total_revenue,
           AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN dim_date d ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    GROUP BY d.d_year, s.s_region
),
category_revenue AS (
    SELECT d.d_year,
           s.s_region,
           p.p_category,
           SUM(lo.lo_revenue) AS cat_revenue
    FROM lineorder lo
    JOIN dim_date d ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    GROUP BY d.d_year, s.s_region, p.p_category
),
top_category AS (
    SELECT d_year,
           s_region,
           p_category,
           cat_revenue
    FROM (
        SELECT d_year,
               s_region,
               p_category,
               cat_revenue,
               ROW_NUMBER() OVER (PARTITION BY d_year, s_region ORDER BY cat_revenue DESC) AS rn
        FROM category_revenue
    ) t
    WHERE rn = 1
)
SELECT ts.d_year,
       ts.s_region,
       ts.total_revenue,
       ts.avg_discount,
       tc.p_category AS top_category,
       tc.cat_revenue AS top_category_revenue
FROM total_stats ts
JOIN top_category tc
  ON ts.d_year = tc.d_year
 AND ts.s_region = tc.s_region
ORDER BY ts.total_revenue DESC
LIMIT 20

WITH
  state_dim AS (
    SELECT DISTINCT s_state
    FROM store
    WHERE s_state IN ('CA', 'TX', 'NY')
  ),
  store_sales_agg AS (
    SELECT d.d_quarter_name AS quarter,
           SUM(ss.ss_net_paid) AS metric
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_quarter_name
  ),
  web_page_agg AS (
    SELECT d.d_quarter_name AS quarter,
           COUNT(*) AS metric
    FROM web_page wp
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    GROUP BY d.d_quarter_name
  ),
  store_cross AS (
    SELECT s.s_state AS region,
           'store' AS source,
           agg.quarter,
           agg.metric
    FROM state_dim s
    CROSS JOIN store_sales_agg agg
  ),
  web_cross AS (
    SELECT s.s_state AS region,
           'web' AS source,
           agg.quarter,
           agg.metric
    FROM state_dim s
    CROSS JOIN web_page_agg agg
  ),
  combined AS (
    SELECT region, source, quarter, metric FROM store_cross
    UNION ALL
    SELECT region, source, quarter, metric FROM web_cross
  )
SELECT
  region,
  source,
  quarter,
  SUM(metric) AS total_metric
FROM combined
GROUP BY ROLLUP (region, source, quarter)
ORDER BY region, source, quarter
LIMIT 100

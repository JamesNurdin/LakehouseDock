WITH
  hour_sales AS (
    SELECT t.t_hour,
           SUM(ss.ss_ext_sales_price) AS hour_sales_total
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 11
    GROUP BY t.t_hour
  ),
  top_stores AS (
    SELECT ss.ss_store_sk,
           SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
    ORDER BY total_sales DESC
    LIMIT 3
  ),
  top_web_sales AS (
    SELECT wp.wp_web_page_sk,
           SUM(ws.ws_ext_sales_price) AS revenue
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY wp.wp_web_page_sk
    ORDER BY revenue DESC
    LIMIT 3
  )
SELECT
  'Store' AS channel_type,
  h.t_hour AS period,
  ps.promo_sales_amount AS revenue,
  p.p_promo_name AS promo_name
FROM hour_sales h
CROSS JOIN top_stores t
CROSS JOIN LATERAL (
  SELECT ss.ss_promo_sk,
         SUM(ss.ss_ext_sales_price) AS promo_sales_amount
  FROM store_sales ss
  WHERE ss.ss_store_sk = t.ss_store_sk
  GROUP BY ss.ss_promo_sk
  ORDER BY promo_sales_amount DESC
  LIMIT 1
) ps
JOIN promotion p ON ps.ss_promo_sk = p.p_promo_sk

UNION

SELECT
  'Web' AS channel_type,
  h.t_hour AS period,
  w.revenue AS revenue,
  CAST(NULL AS varchar) AS promo_name
FROM hour_sales h
CROSS JOIN top_web_sales w

ORDER BY channel_type, period, revenue DESC

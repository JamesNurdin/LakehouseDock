WITH
  sales AS (
    SELECT
      d.d_year,
      p.p_promo_name,
      SUM(ws.ws_net_paid) AS net_paid,
      COUNT(*)           AS cnt_sales
    FROM web_sales ws
      JOIN date_dim d        ON ws.ws_sold_date_sk = d.d_date_sk
      JOIN promotion p       ON ws.ws_promo_sk = p.p_promo_sk
      JOIN web_page w        ON ws.ws_web_page_sk = w.wp_web_page_sk
      JOIN store s           ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND p.p_channel_catalog = 'N'
      AND w.wp_type = 'Home Page'
      AND s.s_state = 'GA'
    GROUP BY d.d_year, p.p_promo_name
  ),
  returns AS (
    SELECT
      d.d_year,
      p.p_promo_name,
      SUM(cr.cr_return_amount) AS return_amount,
      COUNT(*)                AS cnt_returns
    FROM catalog_returns cr
      JOIN date_dim d       ON cr.cr_returned_date_sk = d.d_date_sk
      JOIN promotion p      ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND p.p_channel_catalog = 'N'
    GROUP BY d.d_year, p.p_promo_name
  ),
  combined AS (
    SELECT d_year, p_promo_name, net_paid AS metric, cnt_sales AS cnt, 'sales'   AS src FROM sales
    UNION ALL
    SELECT d_year, p_promo_name, return_amount AS metric, cnt_returns AS cnt, 'returns' AS src FROM returns
  )
SELECT
  d_year,
  p_promo_name,
  AVG(metric) AS avg_metric,
  SUM(cnt)    AS total_cnt
FROM combined
GROUP BY d_year, p_promo_name
HAVING AVG(metric) > 1000
ORDER BY d_year DESC, avg_metric DESC
LIMIT 100

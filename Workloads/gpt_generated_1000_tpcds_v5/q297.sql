SELECT category,
       metric_name,
       metric_value,
       year
FROM (
  SELECT 'Store' AS category,
         s.s_store_id AS metric_name,
         SUM(cr.cr_return_amount) AS metric_value,
         d.d_year AS year
  FROM store s
  JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
  JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
  GROUP BY s.s_store_id, d.d_year
  HAVING SUM(cr.cr_return_amount) > 1000

  UNION ALL

  SELECT 'Promotion' AS category,
         p.p_promo_id AS metric_name,
         SUM(ws.ws_net_profit) AS metric_value,
         d.d_year AS year
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND p.p_channel_tv = 'Y'
  GROUP BY p.p_promo_id, d.d_year
  HAVING SUM(ws.ws_net_profit) > 5000
) AS combined
ORDER BY metric_value DESC, year
LIMIT 100

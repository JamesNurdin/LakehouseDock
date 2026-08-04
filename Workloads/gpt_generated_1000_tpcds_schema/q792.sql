WITH web_agg AS (
  SELECT
    d.d_year AS year,
    'WebNetProfit' AS metric,
    SUM(ws.ws_net_profit) AS total_amount
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_code = 'AIR'
    AND d.d_year = 2001
    AND EXISTS (
      SELECT 1 FROM web_page wp
      WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
        AND wp.wp_link_count > 5
    )
  GROUP BY d.d_year
),
store_agg AS (
  SELECT
    COALESCE(d_sales.d_year, d_return.d_year) AS year,
    'StoreNetResult' AS metric,
    SUM(COALESCE(ss.ss_net_profit, 0) - COALESCE(sr.sr_net_loss, 0)) AS total_amount
  FROM store_sales ss
  FULL OUTER JOIN store_returns sr
    ON ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
  LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
  WHERE COALESCE(d_sales.d_year, d_return.d_year) = 2001
  GROUP BY COALESCE(d_sales.d_year, d_return.d_year)
)
SELECT year, metric, total_amount
FROM web_agg
UNION
SELECT year, metric, total_amount
FROM store_agg
ORDER BY year DESC, metric
OFFSET 0 LIMIT 100

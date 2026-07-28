WITH
  store_data AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      ss.ss_net_paid_inc_tax AS net_sales,
      'Store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Electronics'
  ),
  web_data AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      ws.ws_net_paid_inc_tax AS net_sales,
      'Web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Electronics'
  ),
  combined AS (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
  )
SELECT
  combined.d_year,
  combined.d_month_seq,
  combined.channel,
  CASE WHEN combined.channel = 'Store' THEN 'Physical Store' ELSE 'Online' END AS channel_desc,
  SUM(combined.net_sales) AS total_sales
FROM combined
GROUP BY GROUPING SETS (
  (combined.d_year, combined.d_month_seq, combined.channel),
  (combined.d_year, combined.d_month_seq),
  (combined.d_year),
  ()
)
ORDER BY combined.d_year, combined.d_month_seq, combined.channel
LIMIT 100

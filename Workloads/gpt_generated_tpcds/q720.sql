WITH monthly_activity AS (
  -- Store sales per day
  SELECT d.d_year,
         d.d_month_seq,
         ss.ss_net_paid               AS net_paid,
         ss.ss_net_profit             AS net_profit,
         CAST(0.00 AS decimal(7,2))   AS net_loss,
         'store'                      AS channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'

  UNION ALL

  -- Web sales per day
  SELECT d.d_year,
         d.d_month_seq,
         ws.ws_net_paid,
         ws.ws_net_profit,
         CAST(0.00 AS decimal(7,2)),
         'web'
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'

  UNION ALL

  -- Catalog sales per day
  SELECT d.d_year,
         d.d_month_seq,
         cs.cs_net_paid,
         cs.cs_net_profit,
         CAST(0.00 AS decimal(7,2)),
         'catalog'
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'

  UNION ALL

  -- Catalog returns per day
  SELECT d.d_year,
         d.d_month_seq,
         CAST(0.00 AS decimal(7,2)),
         CAST(0.00 AS decimal(7,2)),
         cr.cr_net_loss,
         'catalog_return'
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'

  UNION ALL

  -- Web returns per day
  SELECT d.d_year,
         d.d_month_seq,
         CAST(0.00 AS decimal(7,2)),
         CAST(0.00 AS decimal(7,2)),
         wr.wr_net_loss,
         'web_return'
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
)
SELECT d_year,
       d_month_seq,
       SUM(CASE WHEN channel = 'store'          THEN net_paid   ELSE 0 END) AS store_sales,
       SUM(CASE WHEN channel = 'store'          THEN net_profit ELSE 0 END) AS store_profit,
       SUM(CASE WHEN channel = 'web'            THEN net_paid   ELSE 0 END) AS web_sales,
       SUM(CASE WHEN channel = 'web'            THEN net_profit ELSE 0 END) AS web_profit,
       SUM(CASE WHEN channel = 'catalog'        THEN net_paid   ELSE 0 END) AS catalog_sales,
       SUM(CASE WHEN channel = 'catalog'        THEN net_profit ELSE 0 END) AS catalog_profit,
       SUM(CASE WHEN channel IN ('catalog_return','web_return') THEN net_loss ELSE 0 END) AS total_return_loss
FROM monthly_activity
GROUP BY d_year, d_month_seq
ORDER BY d_year, d_month_seq

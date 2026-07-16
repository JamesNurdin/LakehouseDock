WITH sales AS (
  SELECT d.d_year AS d_year,
         d.d_moy AS month,
         s.s_state AS state,
         ss.ss_net_paid_inc_tax AS net_paid,
         ss.ss_net_profit AS net_profit,
         CAST(0 AS decimal(15,2)) AS return_loss
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  UNION ALL
  SELECT d.d_year,
         d.d_moy,
         c.cc_state,
         cs.cs_net_paid_inc_tax,
         cs.cs_net_profit,
         CAST(0 AS decimal(15,2))
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
  UNION ALL
  SELECT d.d_year,
         d.d_moy,
         w.web_state,
         ws.ws_net_paid_inc_tax,
         ws.ws_net_profit,
         CAST(0 AS decimal(15,2))
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
),
returns AS (
  SELECT d.d_year AS d_year,
         d.d_moy AS month,
         s.s_state AS state,
         CAST(0 AS decimal(15,2)) AS net_paid,
         CAST(0 AS decimal(15,2)) AS net_profit,
         sr.sr_net_loss AS return_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  UNION ALL
  SELECT d.d_year,
         d.d_moy,
         c.cc_state,
         CAST(0 AS decimal(15,2)),
         CAST(0 AS decimal(15,2)),
         cr.cr_net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN call_center c ON cr.cr_call_center_sk = c.cc_call_center_sk
  UNION ALL
  SELECT d.d_year,
         d.d_moy,
         NULL,
         CAST(0 AS decimal(15,2)),
         CAST(0 AS decimal(15,2)),
         wr.wr_net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
)
SELECT COALESCE(state, 'UNKNOWN') AS state,
       d_year,
       month,
       SUM(net_paid) AS total_net_paid,
       SUM(net_profit) AS total_net_profit,
       SUM(return_loss) AS total_return_loss,
       SUM(net_paid) - SUM(return_loss) AS net_income,
       RANK() OVER (PARTITION BY d_year ORDER BY (SUM(net_paid) - SUM(return_loss)) DESC) AS state_year_rank
FROM (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM returns
) s
WHERE d_year BETWEEN 2000 AND 2002
GROUP BY d_year, month, state
ORDER BY d_year, month, net_income DESC
LIMIT 100

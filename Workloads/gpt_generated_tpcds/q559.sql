WITH unified AS (
  SELECT d.d_date AS d_date,
         cd.cd_gender AS cd_gender,
         ss.ss_net_profit AS net_profit,
         CAST(0 AS decimal(7,2)) AS net_loss
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk

  UNION ALL

  SELECT d.d_date,
         cd.cd_gender,
         cs.cs_net_profit,
         CAST(0 AS decimal(7,2))
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk

  UNION ALL

  SELECT d.d_date,
         cd.cd_gender,
         ws.ws_net_profit,
         CAST(0 AS decimal(7,2))
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk

  UNION ALL

  SELECT d.d_date,
         cd.cd_gender,
         CAST(0 AS decimal(7,2)),
         sr.sr_net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk

  UNION ALL

  SELECT d.d_date,
         cd.cd_gender,
         CAST(0 AS decimal(7,2)),
         cr.cr_net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk

  UNION ALL

  SELECT d.d_date,
         cd.cd_gender,
         CAST(0 AS decimal(7,2)),
         wr.wr_net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
)
SELECT d_date,
       cd_gender,
       SUM(net_profit) AS total_net_profit,
       SUM(net_loss)   AS total_net_loss,
       SUM(net_profit) - SUM(net_loss) AS net_contribution
FROM unified
WHERE d_date >= DATE '2000-01-01' AND d_date < DATE '2001-01-01'
GROUP BY d_date, cd_gender
ORDER BY d_date, cd_gender

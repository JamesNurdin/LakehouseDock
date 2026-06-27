WITH
  store_sales_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      cd.cd_gender,
      SUM(ss.ss_net_profit) AS net_profit,
      0.0 AS net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender
  ),
  store_returns_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      cd.cd_gender,
      0.0 AS net_profit,
      SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender
  ),
  catalog_sales_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      cd.cd_gender,
      SUM(cs.cs_net_profit) AS net_profit,
      0.0 AS net_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender
  ),
  catalog_returns_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      cd.cd_gender,
      0.0 AS net_profit,
      SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender
  ),
  web_sales_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      cd.cd_gender,
      SUM(ws.ws_net_profit) AS net_profit,
      0.0 AS net_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender
  ),
  web_returns_agg AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      cd.cd_gender,
      0.0 AS net_profit,
      SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender
  ),
  combined AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM web_returns_agg
  )
SELECT
  d_year,
  d_month_seq,
  cd_gender,
  SUM(net_profit) AS total_net_profit,
  SUM(net_loss)   AS total_net_loss,
  CASE
    WHEN SUM(net_profit) + SUM(net_loss) = 0 THEN 0
    ELSE ROUND(SUM(net_loss) / (SUM(net_profit) + SUM(net_loss)), 4)
  END AS return_loss_rate
FROM combined
WHERE d_year = 2001
GROUP BY d_year, d_month_seq, cd_gender
ORDER BY d_year, d_month_seq, cd_gender

WITH store_channel AS (
  SELECT
    d.d_year AS year,
    cd.cd_gender AS gender,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_item_sk = sr.sr_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, cd.cd_gender
),
catalog_channel AS (
  SELECT
    d.d_year AS year,
    cd.cd_gender AS gender,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, cd.cd_gender
),
web_channel AS (
  SELECT
    d.d_year AS year,
    cd.cd_gender AS gender,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, cd.cd_gender
)
SELECT
  channel,
  year,
  gender,
  total_sales_profit,
  total_return_loss,
  total_sales_profit - total_return_loss AS net_profit_after_returns
FROM (
  SELECT 'store'   AS channel, year, gender, total_sales_profit, total_return_loss FROM store_channel
  UNION ALL
  SELECT 'catalog' AS channel, year, gender, total_sales_profit, total_return_loss FROM catalog_channel
  UNION ALL
  SELECT 'web'     AS channel, year, gender, total_sales_profit, total_return_loss FROM web_channel
) t
ORDER BY channel, year, gender

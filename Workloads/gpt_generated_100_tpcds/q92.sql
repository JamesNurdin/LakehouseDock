WITH store_sales_agg AS (
  SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_year,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(sr.sr_net_loss) AS store_net_loss
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
  WHERE d.d_year = 2001
  GROUP BY cd.cd_gender, cd.cd_marital_status, d.d_year
),
catalog_sales_agg AS (
  SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_year,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(cr.cr_net_loss) AS catalog_net_loss
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
  WHERE d.d_year = 2001
  GROUP BY cd.cd_gender, cd.cd_marital_status, d.d_year
),
web_sales_agg AS (
  SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_year,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(wr.wr_net_loss) AS web_net_loss
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
  WHERE d.d_year = 2001
  GROUP BY cd.cd_gender, cd.cd_marital_status, d.d_year
)
SELECT
  COALESCE(ss.cd_gender, cs.cd_gender, ws.cd_gender) AS gender,
  COALESCE(ss.cd_marital_status, cs.cd_marital_status, ws.cd_marital_status) AS marital_status,
  COALESCE(ss.d_year, cs.d_year, ws.d_year) AS year,
  COALESCE(ss.store_net_profit, 0) - COALESCE(ss.store_net_loss, 0) +
  COALESCE(cs.catalog_net_profit, 0) - COALESCE(cs.catalog_net_loss, 0) +
  COALESCE(ws.web_net_profit, 0) - COALESCE(ws.web_net_loss, 0) AS total_net_profit
FROM store_sales_agg ss
FULL OUTER JOIN catalog_sales_agg cs
  ON ss.cd_gender = cs.cd_gender
  AND ss.cd_marital_status = cs.cd_marital_status
  AND ss.d_year = cs.d_year
FULL OUTER JOIN web_sales_agg ws
  ON COALESCE(ss.cd_gender, cs.cd_gender) = ws.cd_gender
  AND COALESCE(ss.cd_marital_status, cs.cd_marital_status) = ws.cd_marital_status
  AND COALESCE(ss.d_year, cs.d_year) = ws.d_year
ORDER BY total_net_profit DESC
LIMIT 10

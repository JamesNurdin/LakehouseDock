WITH
  store_sales_agg AS (
    SELECT
      cd.cd_gender AS gender,
      cd.cd_marital_status AS marital_status,
      SUM(ss.ss_net_profit) AS profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
  ),
  catalog_sales_agg AS (
    SELECT
      cd.cd_gender AS gender,
      cd.cd_marital_status AS marital_status,
      SUM(cs.cs_net_profit) AS profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
  ),
  web_sales_agg AS (
    SELECT
      cd.cd_gender AS gender,
      cd.cd_marital_status AS marital_status,
      SUM(ws.ws_net_profit) AS profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
  ),
  total_sales AS (
    SELECT
      gender,
      marital_status,
      SUM(profit) AS total_profit
    FROM (
      SELECT gender, marital_status, profit FROM store_sales_agg
      UNION ALL
      SELECT gender, marital_status, profit FROM catalog_sales_agg
      UNION ALL
      SELECT gender, marital_status, profit FROM web_sales_agg
    ) s
    GROUP BY gender, marital_status
  ),
  store_returns_agg AS (
    SELECT
      cd.cd_gender AS gender,
      cd.cd_marital_status AS marital_status,
      SUM(sr.sr_net_loss) AS loss
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
  ),
  catalog_returns_agg AS (
    SELECT
      cd.cd_gender AS gender,
      cd.cd_marital_status AS marital_status,
      SUM(cr.cr_net_loss) AS loss
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
  ),
  total_returns AS (
    SELECT
      gender,
      marital_status,
      SUM(loss) AS total_loss
    FROM (
      SELECT gender, marital_status, loss FROM store_returns_agg
      UNION ALL
      SELECT gender, marital_status, loss FROM catalog_returns_agg
    ) r
    GROUP BY gender, marital_status
  )
SELECT
  s.gender,
  s.marital_status,
  s.total_profit,
  COALESCE(r.total_loss, 0) AS total_loss,
  s.total_profit - COALESCE(r.total_loss, 0) AS net_contribution
FROM total_sales s
LEFT JOIN total_returns r
  ON s.gender = r.gender
  AND s.marital_status = r.marital_status
ORDER BY net_contribution DESC

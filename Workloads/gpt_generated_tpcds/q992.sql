WITH
  store_sales_agg AS (
    SELECT
      cd.cd_gender,
      cd.cd_marital_status,
      SUM(ss.ss_net_paid_inc_tax) AS store_net_sales,
      SUM(ss.ss_net_profit)       AS store_net_profit
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
  ),
  web_sales_agg AS (
    SELECT
      cd.cd_gender,
      cd.cd_marital_status,
      SUM(ws.ws_net_paid_inc_tax) AS web_net_sales,
      SUM(ws.ws_net_profit)       AS web_net_profit
    FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
  ),
  store_returns_agg AS (
    SELECT
      cd.cd_gender,
      cd.cd_marital_status,
      SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
  ),
  web_returns_agg AS (
    SELECT
      cd.cd_gender,
      cd.cd_marital_status,
      SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
  ),
  catalog_returns_agg AS (
    SELECT
      cd.cd_gender,
      cd.cd_marital_status,
      SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
  )
SELECT
  COALESCE(ssa.cd_gender, wsa.cd_gender, sra.cd_gender, wra.cd_gender, cra.cd_gender) AS gender,
  COALESCE(ssa.cd_marital_status, wsa.cd_marital_status, sra.cd_marital_status, wra.cd_marital_status, cra.cd_marital_status) AS marital_status,
  COALESCE(ssa.store_net_sales, 0) + COALESCE(wsa.web_net_sales, 0)                     AS total_net_sales,
  COALESCE(ssa.store_net_profit, 0) + COALESCE(wsa.web_net_profit, 0)                     AS total_net_profit,
  COALESCE(sra.store_net_loss, 0) + COALESCE(wra.web_net_loss, 0) + COALESCE(cra.catalog_net_loss, 0) AS total_net_loss,
  (COALESCE(ssa.store_net_profit, 0) + COALESCE(wsa.web_net_profit, 0)) -
    (COALESCE(sra.store_net_loss, 0) + COALESCE(wra.web_net_loss, 0) + COALESCE(cra.catalog_net_loss, 0)) AS net_profit_after_returns
FROM store_sales_agg ssa
FULL OUTER JOIN web_sales_agg wsa
  ON ssa.cd_gender = wsa.cd_gender AND ssa.cd_marital_status = wsa.cd_marital_status
FULL OUTER JOIN store_returns_agg sra
  ON COALESCE(ssa.cd_gender, wsa.cd_gender) = sra.cd_gender
     AND COALESCE(ssa.cd_marital_status, wsa.cd_marital_status) = sra.cd_marital_status
FULL OUTER JOIN web_returns_agg wra
  ON COALESCE(ssa.cd_gender, wsa.cd_gender, sra.cd_gender) = wra.cd_gender
     AND COALESCE(ssa.cd_marital_status, wsa.cd_marital_status, sra.cd_marital_status) = wra.cd_marital_status
FULL OUTER JOIN catalog_returns_agg cra
  ON COALESCE(ssa.cd_gender, wsa.cd_gender, sra.cd_gender, wra.cd_gender) = cra.cd_gender
     AND COALESCE(ssa.cd_marital_status, wsa.cd_marital_status, sra.cd_marital_status, wra.cd_marital_status) = cra.cd_marital_status
ORDER BY gender, marital_status

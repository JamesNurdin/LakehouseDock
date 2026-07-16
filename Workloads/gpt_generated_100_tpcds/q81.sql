WITH
  store_sales_income AS (
    SELECT
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      SUM(ss.ss_net_profit) AS store_sales_profit
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
  ),
  store_returns_income AS (
    SELECT
      ib.ib_income_band_sk,
      SUM(sr.sr_net_loss) AS store_returns_loss
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
  ),
  catalog_sales_income AS (
    SELECT
      ib.ib_income_band_sk,
      SUM(cs.cs_net_profit) AS catalog_sales_profit
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
  ),
  catalog_returns_income AS (
    SELECT
      ib.ib_income_band_sk,
      SUM(cr.cr_net_loss) AS catalog_returns_loss
    FROM catalog_returns cr
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
  ),
  web_sales_income AS (
    SELECT
      ib.ib_income_band_sk,
      SUM(ws.ws_net_profit) AS web_sales_profit
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
  ),
  web_returns_income AS (
    SELECT
      ib.ib_income_band_sk,
      SUM(wr.wr_net_loss) AS web_returns_loss
    FROM web_returns wr
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
  )
SELECT
  ib.ib_income_band_sk,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  COALESCE(ss.store_sales_profit, 0) - COALESCE(sr.store_returns_loss, 0) +
  COALESCE(cs.catalog_sales_profit, 0) - COALESCE(cr.catalog_returns_loss, 0) +
  COALESCE(ws.web_sales_profit, 0) - COALESCE(wr.web_returns_loss, 0) AS net_profit_after_returns
FROM income_band ib
LEFT JOIN store_sales_income ss ON ib.ib_income_band_sk = ss.ib_income_band_sk
LEFT JOIN store_returns_income sr ON ib.ib_income_band_sk = sr.ib_income_band_sk
LEFT JOIN catalog_sales_income cs ON ib.ib_income_band_sk = cs.ib_income_band_sk
LEFT JOIN catalog_returns_income cr ON ib.ib_income_band_sk = cr.ib_income_band_sk
LEFT JOIN web_sales_income ws ON ib.ib_income_band_sk = ws.ib_income_band_sk
LEFT JOIN web_returns_income wr ON ib.ib_income_band_sk = wr.ib_income_band_sk
ORDER BY net_profit_after_returns DESC
LIMIT 10

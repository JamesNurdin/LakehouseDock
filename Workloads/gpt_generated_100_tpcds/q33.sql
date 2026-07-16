WITH
  store_sales_agg AS (
    SELECT
      d.d_year AS year,
      cd.cd_gender AS gender,
      SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, cd.cd_gender
  ),
  store_returns_agg AS (
    SELECT
      d.d_year AS year,
      cd.cd_gender AS gender,
      SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, cd.cd_gender
  ),
  catalog_sales_agg AS (
    SELECT
      d.d_year AS year,
      cd.cd_gender AS gender,
      SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, cd.cd_gender
  ),
  catalog_returns_agg AS (
    SELECT
      d.d_year AS year,
      cd.cd_gender AS gender,
      SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, cd.cd_gender
  ),
  web_sales_agg AS (
    SELECT
      d.d_year AS year,
      cd.cd_gender AS gender,
      SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, cd.cd_gender
  ),
  web_returns_agg AS (
    SELECT
      d.d_year AS year,
      cd.cd_gender AS gender,
      SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, cd.cd_gender
  )
SELECT
  ss.year,
  ss.gender,
  COALESCE(ss.store_net_profit, 0) - COALESCE(sr.store_net_loss, 0) +
  COALESCE(cs.catalog_net_profit, 0) - COALESCE(cr.catalog_net_loss, 0) +
  COALESCE(ws.web_net_profit, 0) - COALESCE(wr.web_net_loss, 0) AS net_profit_after_returns
FROM store_sales_agg ss
LEFT JOIN store_returns_agg sr ON ss.year = sr.year AND ss.gender = sr.gender
LEFT JOIN catalog_sales_agg cs ON ss.year = cs.year AND ss.gender = cs.gender
LEFT JOIN catalog_returns_agg cr ON ss.year = cr.year AND ss.gender = cr.gender
LEFT JOIN web_sales_agg ws ON ss.year = ws.year AND ss.gender = ws.gender
LEFT JOIN web_returns_agg wr ON ss.year = wr.year AND ss.gender = wr.gender
ORDER BY net_profit_after_returns DESC
LIMIT 5

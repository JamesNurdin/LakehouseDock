WITH
  store AS (
    SELECT
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cd.cd_gender,
      SUM(ss.ss_net_profit) AS total_profit,
      SUM(sr.sr_net_loss) AS total_loss
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
      AND sr.sr_customer_sk = c.c_customer_sk
      AND sr.sr_cdemo_sk = cd.cd_demo_sk
      AND sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, cd.cd_gender
  ),
  catalog AS (
    SELECT
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cd.cd_gender,
      SUM(cs.cs_net_profit) AS total_profit,
      SUM(cr.cr_net_loss) AS total_loss
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
      AND cr.cr_refunded_customer_sk = c.c_customer_sk
      AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
      AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, cd.cd_gender
  ),
  web AS (
    SELECT
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cd.cd_gender,
      SUM(ws.ws_net_profit) AS total_profit,
      SUM(wr.wr_net_loss) AS total_loss
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
      AND wr.wr_refunded_customer_sk = c.c_customer_sk
      AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
      AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, cd.cd_gender
  )
SELECT
  income_band_lower,
  income_band_upper,
  gender,
  SUM(total_profit) AS total_profit,
  SUM(total_loss)   AS total_loss,
  SUM(total_profit) - SUM(total_loss) AS net_profit
FROM (
  SELECT ib_lower_bound AS income_band_lower,
         ib_upper_bound AS income_band_upper,
         cd_gender      AS gender,
         total_profit,
         total_loss
  FROM store
  UNION ALL
  SELECT ib_lower_bound,
         ib_upper_bound,
         cd_gender,
         total_profit,
         total_loss
  FROM catalog
  UNION ALL
  SELECT ib_lower_bound,
         ib_upper_bound,
         cd_gender,
         total_profit,
         total_loss
  FROM web
) AS combined
GROUP BY income_band_lower, income_band_upper, gender
ORDER BY income_band_lower, gender

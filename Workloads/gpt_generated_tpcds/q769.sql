WITH sales_and_losses AS (
   SELECT cd.cd_gender AS gender,
          ib.ib_lower_bound AS lower_income,
          ib.ib_upper_bound AS upper_income,
          ss.ss_net_profit AS profit,
          CAST(0 AS decimal(7,2)) AS loss
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

   UNION ALL

   SELECT cd.cd_gender AS gender,
          ib.ib_lower_bound AS lower_income,
          ib.ib_upper_bound AS upper_income,
          CAST(0 AS decimal(7,2)) AS profit,
          sr.sr_net_loss AS loss
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

   UNION ALL

   SELECT cd.cd_gender AS gender,
          ib.ib_lower_bound AS lower_income,
          ib.ib_upper_bound AS upper_income,
          cs.cs_net_profit AS profit,
          CAST(0 AS decimal(7,2)) AS loss
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

   UNION ALL

   SELECT cd.cd_gender AS gender,
          ib.ib_lower_bound AS lower_income,
          ib.ib_upper_bound AS upper_income,
          CAST(0 AS decimal(7,2)) AS profit,
          cr.cr_net_loss AS loss
   FROM catalog_returns cr
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

   UNION ALL

   SELECT cd.cd_gender AS gender,
          ib.ib_lower_bound AS lower_income,
          ib.ib_upper_bound AS upper_income,
          ws.ws_net_profit AS profit,
          CAST(0 AS decimal(7,2)) AS loss
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

   UNION ALL

   SELECT cd.cd_gender AS gender,
          ib.ib_lower_bound AS lower_income,
          ib.ib_upper_bound AS upper_income,
          CAST(0 AS decimal(7,2)) AS profit,
          wr.wr_net_loss AS loss
   FROM web_returns wr
   JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT gender,
       lower_income,
       upper_income,
       SUM(profit) AS total_profit,
       SUM(loss) AS total_loss,
       SUM(profit) - SUM(loss) AS net_profit
FROM sales_and_losses
GROUP BY gender, lower_income, upper_income
ORDER BY total_profit DESC
LIMIT 10

WITH
store_sales_agg AS (
   SELECT
     ca.ca_state AS state,
     ib.ib_lower_bound AS income_lower,
     ib.ib_upper_bound AS income_upper,
     cd.cd_gender AS gender,
     SUM(ss.ss_net_profit) AS net_profit,
     SUM(ss.ss_ext_sales_price) AS sales_amount,
     COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   GROUP BY ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound, cd.cd_gender
),
catalog_sales_agg AS (
   SELECT
     ca.ca_state AS state,
     ib.ib_lower_bound AS income_lower,
     ib.ib_upper_bound AS income_upper,
     cd.cd_gender AS gender,
     SUM(cs.cs_net_profit) AS net_profit,
     SUM(cs.cs_ext_sales_price) AS sales_amount,
     COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   GROUP BY ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound, cd.cd_gender
),
web_sales_agg AS (
   SELECT
     ca.ca_state AS state,
     ib.ib_lower_bound AS income_lower,
     ib.ib_upper_bound AS income_upper,
     cd.cd_gender AS gender,
     SUM(ws.ws_net_profit) AS net_profit,
     SUM(ws.ws_ext_sales_price) AS sales_amount,
     COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   GROUP BY ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound, cd.cd_gender
),
store_returns_agg AS (
   SELECT
     ca.ca_state AS state,
     ib.ib_lower_bound AS income_lower,
     ib.ib_upper_bound AS income_upper,
     cd.cd_gender AS gender,
     SUM(sr.sr_net_loss) AS net_loss,
     COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   GROUP BY ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound, cd.cd_gender
),
catalog_returns_agg AS (
   SELECT
     ca.ca_state AS state,
     ib.ib_lower_bound AS income_lower,
     ib.ib_upper_bound AS income_upper,
     cd.cd_gender AS gender,
     SUM(cr.cr_net_loss) AS net_loss,
     COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_customers
   FROM catalog_returns cr
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   GROUP BY ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound, cd.cd_gender
),
web_returns_agg AS (
   SELECT
     ca.ca_state AS state,
     ib.ib_lower_bound AS income_lower,
     ib.ib_upper_bound AS income_upper,
     cd.cd_gender AS gender,
     SUM(wr.wr_net_loss) AS net_loss,
     COUNT(DISTINCT wr.wr_refunded_customer_sk) AS distinct_customers
   FROM web_returns wr
   JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   GROUP BY ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound, cd.cd_gender
),
combined AS (
   SELECT state, income_lower, income_upper, gender,
          net_profit,
          CAST(0 AS decimal(7,2)) AS net_loss,
          distinct_customers
   FROM store_sales_agg
   UNION ALL
   SELECT state, income_lower, income_upper, gender,
          net_profit,
          CAST(0 AS decimal(7,2)) AS net_loss,
          distinct_customers
   FROM catalog_sales_agg
   UNION ALL
   SELECT state, income_lower, income_upper, gender,
          net_profit,
          CAST(0 AS decimal(7,2)) AS net_loss,
          distinct_customers
   FROM web_sales_agg
   UNION ALL
   SELECT state, income_lower, income_upper, gender,
          CAST(0 AS decimal(7,2)) AS net_profit,
          net_loss,
          distinct_customers
   FROM store_returns_agg
   UNION ALL
   SELECT state, income_lower, income_upper, gender,
          CAST(0 AS decimal(7,2)) AS net_profit,
          net_loss,
          distinct_customers
   FROM catalog_returns_agg
   UNION ALL
   SELECT state, income_lower, income_upper, gender,
          CAST(0 AS decimal(7,2)) AS net_profit,
          net_loss,
          distinct_customers
   FROM web_returns_agg
)
SELECT
   state,
   income_lower,
   income_upper,
   gender,
   SUM(net_profit) AS total_net_profit,
   SUM(net_loss) AS total_net_loss,
   SUM(net_profit) - SUM(net_loss) AS net_contribution,
   SUM(distinct_customers) AS total_distinct_customers
FROM combined
GROUP BY state, income_lower, income_upper, gender
ORDER BY net_contribution DESC
LIMIT 100

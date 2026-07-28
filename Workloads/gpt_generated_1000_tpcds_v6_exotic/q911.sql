WITH high_income AS (
   SELECT
       c.c_customer_id,
       c.c_email_address,
       SUM(sr.sr_net_loss) AS total_net_loss
   FROM store_returns sr
   INNER JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   INNER JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
   WHERE ib.ib_lower_bound >= 60000
     AND s.s_country = 'United States'
   GROUP BY c.c_customer_id, c.c_email_address
),
low_income AS (
   SELECT
       c.c_customer_id,
       c.c_email_address,
       SUM(sr.sr_net_loss) AS total_net_loss
   FROM store_returns sr
   INNER JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   INNER JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ib.ib_upper_bound <= 30000
   GROUP BY c.c_customer_id, c.c_email_address
)
SELECT DISTINCT
   customer_id,
   email_address,
   total_net_loss
FROM (
   SELECT c_customer_id AS customer_id, c_email_address AS email_address, total_net_loss FROM high_income
   UNION ALL
   SELECT c_customer_id AS customer_id, c_email_address AS email_address, total_net_loss FROM low_income
) combined
ORDER BY total_net_loss DESC
LIMIT 100

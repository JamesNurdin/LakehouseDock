WITH male_sales AS (
   SELECT
       ca.ca_state,
       cd.cd_gender,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       AVG(ss.ss_net_profit) AS avg_net_profit,
       COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
   FROM store_sales ss
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE cd.cd_gender = 'M'
     AND ib.ib_lower_bound >= 50000
     AND ca.ca_country = 'United States'
     AND ca.ca_state IN ('CA', 'TX', 'NY')
   GROUP BY ca.ca_state, cd.cd_gender
),
female_sales AS (
   SELECT
       ca.ca_state,
       cd.cd_gender,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       AVG(ss.ss_net_profit) AS avg_net_profit,
       COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
   FROM store_sales ss
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE cd.cd_gender = 'F'
     AND hd.hd_buy_potential = '5001-10000'
     AND ca.ca_country = 'United States'
     AND ca.ca_state IN ('FL', 'IL', 'PA')
   GROUP BY ca.ca_state, cd.cd_gender
)
SELECT *
FROM male_sales
UNION ALL
SELECT *
FROM female_sales
ORDER BY total_sales DESC
LIMIT 100

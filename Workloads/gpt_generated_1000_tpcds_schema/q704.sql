WITH sales_union AS (
   SELECT
      ca.ca_state AS state,
      cd.cd_gender AS gender,
      ib.ib_lower_bound AS income_lower,
      cs.cs_net_profit AS profit
   FROM catalog_sales cs
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE td.t_hour = 10
     AND cd.cd_purchase_estimate > 5000
     AND ib.ib_upper_bound <= 90000
     AND ca.ca_state = 'CA'
   UNION DISTINCT
   SELECT
      ca.ca_state AS state,
      cd.cd_gender AS gender,
      ib.ib_lower_bound AS income_lower,
      ss.ss_net_profit AS profit
   FROM store_sales ss
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE td.t_hour = 10
     AND cd.cd_purchase_estimate > 5000
     AND ib.ib_upper_bound <= 90000
     AND ca.ca_state = 'CA'
),
agg AS (
   SELECT
      state,
      gender,
      income_lower,
      SUM(profit) AS total_profit,
      CASE
         WHEN SUM(profit) > 10000 THEN 'High'
         WHEN SUM(profit) > 5000  THEN 'Medium'
         ELSE 'Low'
      END AS profit_category
   FROM sales_union
   GROUP BY ROLLUP (state, gender, income_lower)
)
SELECT
   state,
   gender,
   income_lower,
   total_profit,
   profit_category,
   ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_profit DESC) AS profit_rank,
   (SELECT AVG(total_profit) FROM agg) AS avg_total_profit_across_all
FROM agg
ORDER BY state, gender NULLS LAST, income_lower NULLS LAST

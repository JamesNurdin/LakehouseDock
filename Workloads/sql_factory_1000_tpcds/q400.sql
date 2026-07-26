WITH demog_sales AS (
    SELECT cd.cd_demo_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           SUM(cs.cs_net_profit) AS sales_profit
    FROM catalog_sales cs
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
), demog_returns AS (
    SELECT cd.cd_demo_sk,
           SUM(sr.sr_net_loss) AS return_loss,
           MIN(s.s_store_name) AS example_store_name
    FROM store_returns sr
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    GROUP BY cd.cd_demo_sk
)
SELECT d.cd_demo_sk,
       d.cd_gender,
       d.cd_marital_status,
       d.sales_profit,
       COALESCE(r.return_loss, 0) AS return_loss,
       d.sales_profit - COALESCE(r.return_loss, 0) AS net_balance,
       RANK() OVER (ORDER BY d.sales_profit - COALESCE(r.return_loss, 0) DESC) AS profit_rank,
       CASE 
           WHEN d.sales_profit - COALESCE(r.return_loss, 0) > 10000 THEN 'High'
           WHEN d.sales_profit - COALESCE(r.return_loss, 0) > 0 THEN 'Medium'
           ELSE 'Low'
       END AS balance_category,
       r.example_store_name
FROM demog_sales d
LEFT JOIN demog_returns r
  ON d.cd_demo_sk = r.cd_demo_sk
ORDER BY profit_rank
LIMIT 20

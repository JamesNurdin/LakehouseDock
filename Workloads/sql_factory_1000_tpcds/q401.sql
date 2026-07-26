WITH store_agg AS (
   SELECT s.s_store_sk,
          s.s_store_name,
          s.s_city,
          s.s_state,
          SUM(sr.sr_return_amt) AS total_return_amount,
          SUM(sr.sr_net_loss) AS total_net_loss,
          AVG(sr.sr_return_tax) AS avg_return_tax,
          COUNT(*) AS return_transactions,
          SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS male_return_ratio,
          COALESCE(SUM(cs.cs_net_profit), 0) AS total_sales_profit
   FROM store_returns sr
   JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   JOIN customer_demographics cd
     ON sr.sr_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN catalog_sales cs
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   GROUP BY s.s_store_sk, s.s_store_name, s.s_city, s.s_state
)
SELECT s_store_sk,
       s_store_name,
       s_city,
       s_state,
       total_return_amount,
       total_net_loss,
       avg_return_tax,
       return_transactions,
       male_return_ratio,
       total_sales_profit,
       PERCENT_RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_percentile,
       SUM(total_net_loss) OVER (ORDER BY total_net_loss DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss,
       CASE 
           WHEN total_net_loss > 50000 THEN 'High Loss'
           WHEN total_net_loss > 20000 THEN 'Medium Loss'
           ELSE 'Low Loss'
       END AS loss_category
FROM store_agg
ORDER BY total_net_loss DESC
LIMIT 15

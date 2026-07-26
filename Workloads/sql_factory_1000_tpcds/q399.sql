WITH sales_events AS (
    SELECT cs.cs_sold_date_sk AS event_date,
           cd.cd_demo_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           cs.cs_net_profit AS net_amount,
           'sale' AS event_type,
           NULL AS store_name
    FROM catalog_sales cs
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
), return_events AS (
    SELECT sr.sr_returned_date_sk AS event_date,
           cd.cd_demo_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           -sr.sr_net_loss AS net_amount,
           'return' AS event_type,
           s.s_store_name AS store_name
    FROM store_returns sr
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
), all_events AS (
    SELECT event_date,
           cd_demo_sk,
           cd_gender,
           cd_marital_status,
           net_amount,
           event_type,
           store_name
    FROM sales_events
    UNION ALL
    SELECT event_date,
           cd_demo_sk,
           cd_gender,
           cd_marital_status,
           net_amount,
           event_type,
           store_name
    FROM return_events
), cumulative_events AS (
    SELECT event_date,
           cd_demo_sk,
           cd_gender,
           cd_marital_status,
           net_amount,
           event_type,
           store_name,
           SUM(net_amount) OVER (PARTITION BY cd_demo_sk ORDER BY event_date
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
    FROM all_events
), final AS (
    SELECT event_date,
           cd_demo_sk,
           cd_gender,
           cd_marital_status,
           net_amount,
           event_type,
           store_name,
           cumulative_profit,
           LAG(cumulative_profit) OVER (PARTITION BY cd_demo_sk ORDER BY event_date) AS previous_cumulative_profit
    FROM cumulative_events
)
SELECT cd_demo_sk,
       cd_gender,
       cd_marital_status,
       MAX(event_date) AS latest_event_date,
       MAX(cumulative_profit) AS total_cumulative_profit,
       MAX(previous_cumulative_profit) AS previous_cumulative_profit,
       (MAX(cumulative_profit) - COALESCE(MAX(previous_cumulative_profit),0)) AS recent_change,
       CASE 
           WHEN (MAX(cumulative_profit) - COALESCE(MAX(previous_cumulative_profit),0)) > 5000 THEN 'Significant Increase'
           WHEN (MAX(cumulative_profit) - COALESCE(MAX(previous_cumulative_profit),0)) < -5000 THEN 'Significant Decrease'
           ELSE 'Stable'
       END AS change_flag
FROM final
GROUP BY cd_demo_sk, cd_gender, cd_marital_status
ORDER BY total_cumulative_profit DESC
LIMIT 10

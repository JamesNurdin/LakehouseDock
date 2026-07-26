WITH customer_stats AS (
  SELECT
    cs.cs_bill_customer_sk,
    cs.cs_sold_date_sk,
    cs.cs_net_profit,
    SUM(cs.cs_net_profit) OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.cs_sold_date_sk) AS cumulative_profit,
    AVG(cs.cs_net_profit) OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.cs_sold_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3,
    SUM(cs.cs_net_profit) OVER (PARTITION BY cs.cs_bill_customer_sk) AS total_profit
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
),
ranked_customers AS (
  SELECT
    cs_bill_customer_sk,
    MAX(total_profit) AS total_profit,
    DENSE_RANK() OVER (ORDER BY MAX(total_profit) DESC) AS customer_rank
  FROM customer_stats
  GROUP BY cs_bill_customer_sk
)
SELECT
  cs.cs_bill_customer_sk,
  cs.cs_sold_date_sk,
  cs.cs_net_profit,
  cs.cumulative_profit,
  cs.moving_avg_3,
  CASE
    WHEN cs.cumulative_profit >= 10000 THEN 'High'
    WHEN cs.cumulative_profit >= 5000 THEN 'Medium'
    ELSE 'Low'
  END AS profit_bracket,
  rc.customer_rank
FROM customer_stats cs
JOIN ranked_customers rc ON cs.cs_bill_customer_sk = rc.cs_bill_customer_sk
WHERE rc.customer_rank <= 5
ORDER BY rc.customer_rank, cs.cs_sold_date_sk

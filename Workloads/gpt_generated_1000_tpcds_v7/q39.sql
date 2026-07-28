WITH base AS (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    t.t_hour,
    cs.cs_net_profit AS catalog_profit,
    ss.ss_net_profit AS store_profit,
    wr.wr_net_loss AS return_loss
  FROM catalog_sales cs
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN store_sales ss
    ON ss.ss_sold_time_sk = t.t_time_sk
   AND ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = t.t_time_sk
   AND wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE cs.cs_net_profit > 1000
    AND ss.ss_net_profit < 0
    AND t.t_hour BETWEEN 9 AND 17
),
agg AS (
  SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    t_hour,
    SUM(catalog_profit) AS total_catalog_profit,
    SUM(store_profit) AS total_store_profit,
    SUM(return_loss) AS total_return_loss,
    SUM(catalog_profit) + SUM(store_profit) + SUM(return_loss) AS net_total
  FROM base
  GROUP BY c_customer_sk, c_first_name, c_last_name, t_hour
  HAVING SUM(catalog_profit) + SUM(store_profit) + SUM(return_loss) > 0
)
SELECT
  c_customer_sk,
  c_first_name,
  c_last_name,
  t_hour,
  total_catalog_profit,
  total_store_profit,
  total_return_loss,
  net_total,
  RANK() OVER (ORDER BY net_total DESC) AS profit_rank,
  SUM(total_store_profit) OVER (PARTITION BY t_hour ORDER BY net_total ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_store_profit_3rows,
  CASE
    WHEN (SELECT COUNT(*) FROM reason r_sub WHERE r_sub.r_reason_desc = 'Customer not satisfied') > 0
      THEN 'Frequent Issue'
    ELSE 'Other'
  END AS reason_category_flag
FROM agg
ORDER BY profit_rank
LIMIT 100

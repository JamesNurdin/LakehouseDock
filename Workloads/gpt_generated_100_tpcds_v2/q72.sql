WITH daily_store_sales AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    ss.ss_sold_date_sk AS sold_date_sk,
    SUM(ss.ss_net_profit) AS daily_net_profit,
    SUM(ss.ss_ext_discount_amt) AS daily_discount_amt
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  GROUP BY s.s_store_sk, s.s_store_name, ss.ss_sold_date_sk
)
SELECT
  d.s_store_name,
  d.sold_date_sk,
  d.daily_net_profit,
  d.daily_discount_amt,
  AVG(d.daily_net_profit) OVER (
    PARTITION BY d.s_store_name
    ORDER BY d.sold_date_sk
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS moving_avg_7day_profit,
  RANK() OVER (
    PARTITION BY d.sold_date_sk
    ORDER BY d.daily_net_profit DESC
  ) AS profit_rank,
  CASE WHEN d.daily_discount_amt > 1000 THEN 'High Discount' ELSE 'Normal' END AS discount_category
FROM daily_store_sales d
ORDER BY d.sold_date_sk, profit_rank

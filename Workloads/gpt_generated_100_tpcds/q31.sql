WITH sales_agg AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    td.t_hour,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    COUNT(*) AS sales_transactions
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  WHERE td.t_hour BETWEEN 9 AND 18
  GROUP BY s.s_store_sk, s.s_store_name, td.t_hour
),
returns_agg AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    td.t_hour,
    r.r_reason_desc,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    COUNT(*) AS return_transactions
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE td.t_hour BETWEEN 9 AND 18
  GROUP BY s.s_store_sk, s.s_store_name, td.t_hour, r.r_reason_desc
)
SELECT
  s.s_store_name,
  s.t_hour,
  s.total_sales_amount,
  s.total_sales_profit,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
  s.distinct_customers,
  s.sales_transactions,
  r.r_reason_desc,
  (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) /
    SUM(s.total_sales_profit - COALESCE(r.total_return_loss, 0)) OVER (PARTITION BY s.t_hour) AS profit_share_of_hour
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.s_store_sk = r.s_store_sk
 AND s.t_hour = r.t_hour
ORDER BY s.total_sales_amount DESC
LIMIT 20

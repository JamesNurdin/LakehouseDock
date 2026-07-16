WITH sales_agg AS (
  SELECT
    ss.ss_store_sk AS store_sk,
    d_sales.d_year,
    d_sales.d_quarter_seq,
    d_sales.d_month_seq,
    cd.cd_credit_rating,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss,
    SUM(ss.ss_quantity) AS total_sold_qty,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_qty
  FROM store_sales ss
  JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
  WHERE cd.cd_credit_rating = 'Good'
    AND cd.cd_purchase_estimate >= 1500
    AND d_sales.d_year = 2001
    AND d_sales.d_weekend = 'Y'
  GROUP BY ss.ss_store_sk, d_sales.d_year, d_sales.d_quarter_seq, d_sales.d_month_seq, cd.cd_credit_rating
  HAVING SUM(ss.ss_quantity) > 1000
)
SELECT
  store_sk,
  d_year,
  d_quarter_seq,
  d_month_seq,
  cd_credit_rating,
  total_transactions,
  total_sales_profit,
  total_return_loss,
  (total_sales_profit - total_return_loss) AS net_profit_after_returns,
  total_return_qty,
  total_sold_qty,
  CASE WHEN total_sold_qty = 0 THEN 0
       ELSE total_return_qty * 1.0 / total_sold_qty END AS return_rate,
  RANK() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY (total_sales_profit - total_return_loss) DESC) AS profit_rank_qtr
FROM sales_agg
ORDER BY net_profit_after_returns DESC
LIMIT 100

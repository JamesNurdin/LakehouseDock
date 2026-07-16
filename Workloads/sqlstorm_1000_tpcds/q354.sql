WITH
sales_agg AS (
  SELECT d.d_year,
         d.d_moy AS month_num,
         s.s_store_id,
         i.i_category,
         SUM(ss.ss_net_profit) AS total_sales_profit,
         SUM(ss.ss_quantity) AS total_quantity_sold,
         SUM(ss.ss_ext_sales_price) AS total_sales_amount
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_moy, s.s_store_id, i.i_category
),
returns_agg AS (
  SELECT d.d_year,
         d.d_moy AS month_num,
         s.s_store_id,
         i.i_category,
         SUM(sr.sr_net_loss) AS total_return_loss,
         SUM(sr.sr_return_quantity) AS total_quantity_returned,
         SUM(sr.sr_return_amt) AS total_return_amount
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_moy, s.s_store_id, i.i_category
)
SELECT
  COALESCE(sales_agg.d_year, returns_agg.d_year) AS year,
  COALESCE(sales_agg.month_num, returns_agg.month_num) AS month,
  COALESCE(sales_agg.s_store_id, returns_agg.s_store_id) AS store_id,
  COALESCE(sales_agg.i_category, returns_agg.i_category) AS category,
  COALESCE(sales_agg.total_sales_profit, 0) AS total_sales_profit,
  COALESCE(returns_agg.total_return_loss, 0) AS total_return_loss,
  COALESCE(sales_agg.total_sales_profit, 0) - COALESCE(returns_agg.total_return_loss, 0) AS net_profit,
  COALESCE(sales_agg.total_quantity_sold, 0) AS total_quantity_sold,
  COALESCE(returns_agg.total_quantity_returned, 0) AS total_quantity_returned,
  COALESCE(sales_agg.total_sales_amount, 0) AS total_sales_amount,
  COALESCE(returns_agg.total_return_amount, 0) AS total_return_amount
FROM sales_agg
FULL OUTER JOIN returns_agg
  ON sales_agg.d_year = returns_agg.d_year
 AND sales_agg.month_num = returns_agg.month_num
 AND sales_agg.s_store_id = returns_agg.s_store_id
 AND sales_agg.i_category = returns_agg.i_category
ORDER BY year DESC, month DESC, store_id, category
LIMIT 100

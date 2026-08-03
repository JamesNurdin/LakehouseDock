WITH base AS (
   SELECT
      s_sales.s_store_name,
      i_sold.i_product_name,
      t_sales.t_hour,
      t_return.t_meal_time AS return_meal_time,
      SUM(ss_ext_sales_price) AS total_sales,
      SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
      SUM(ss_net_profit) AS sum_profit,
      SUM(COALESCE(sr.sr_net_loss, 0)) AS sum_return_loss,
      r.r_reason_desc,
      SUM(qty) AS total_inventory_qty
   FROM store_sales ss
   JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
   JOIN item i_sold ON ss.ss_item_sk = i_sold.i_item_sk
   JOIN store s_sales ON ss.ss_store_sk = s_sales.s_store_sk
   FULL OUTER JOIN inventory inv ON i_sold.i_item_sk = inv.inv_item_sk
   CROSS JOIN UNNEST(ARRAY[COALESCE(inv.inv_quantity_on_hand, 0)]) AS u(qty)
   LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
   JOIN item i_return ON sr.sr_item_sk = i_return.i_item_sk
   JOIN store s_return ON sr.sr_store_sk = s_return.s_store_sk
   WHERE ss.ss_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'BrandX')
   GROUP BY
      s_sales.s_store_name,
      i_sold.i_product_name,
      t_sales.t_hour,
      t_return.t_meal_time,
      r.r_reason_desc
)
SELECT
   s_store_name,
   i_product_name,
   t_hour,
   return_meal_time,
   total_sales,
   total_returns,
   (sum_profit - sum_return_loss) AS net_profit,
   CASE WHEN (sum_profit - sum_return_loss) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag,
   total_inventory_qty,
   ROW_NUMBER() OVER (ORDER BY (sum_profit - sum_return_loss) DESC) AS global_rank,
   LAG(total_sales) OVER (PARTITION BY s_store_name ORDER BY t_hour) AS prev_sales,
   r_reason_desc
FROM base
ORDER BY net_profit DESC
LIMIT 100

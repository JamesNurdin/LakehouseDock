WITH
sales_union AS (
  SELECT cs_order_number AS order_id,
         cs_item_sk AS item_sk,
         cs_sold_date_sk AS date_sk,
         cs_net_paid AS net_paid,
         cs_net_profit AS net_profit,
         cs_quantity AS quantity,
         'catalog' AS channel
  FROM catalog_sales
  UNION ALL
  SELECT ss_ticket_number AS order_id,
         ss_item_sk AS item_sk,
         ss_sold_date_sk AS date_sk,
         ss_net_paid AS net_paid,
         ss_net_profit AS net_profit,
         ss_quantity AS quantity,
         'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT ws_order_number AS order_id,
         ws_item_sk AS item_sk,
         ws_sold_date_sk AS date_sk,
         ws_net_paid AS net_paid,
         ws_net_profit AS net_profit,
         ws_quantity AS quantity,
         'web' AS channel
  FROM web_sales
),
sales_with_dates AS (
  SELECT su.*,
         d.d_date,
         d.d_year,
         d.d_month_seq,
         d.d_week_seq,
         d.d_day_name,
         d.d_holiday
  FROM sales_union su
  LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
),
item_dim_extended AS (
  SELECT i.*,
         concat_ws('_', lower(i.i_brand), i.i_color, coalesce(i.i_size, 'NA')) AS brand_color_size_key,
         regexp_replace(i.i_product_name, '[^a-zA-Z0-9]', '') AS clean_product_name,
         CASE WHEN i.i_size IS NULL THEN 'UNKNOWN_SIZE' ELSE i.i_size END AS size_filled
  FROM item i
),
aggregated_sales AS (
  SELECT swd.item_sk,
         i.i_product_name,
         i.i_category,
         i.i_brand,
         i.i_color,
         i.i_size,
         swd.channel,
         SUM(swd.net_paid) AS total_net_paid,
         SUM(swd.net_profit) AS total_net_profit,
         COUNT(*) AS sales_cnt,
         AVG(swd.net_paid) AS avg_net_paid,
         MAX(swd.net_paid) AS max_net_paid,
         MIN(swd.net_paid) AS min_net_paid,
         MIN(swd.date_sk) AS first_date_sk,
         MAX(swd.date_sk) AS last_date_sk
  FROM sales_with_dates swd
  LEFT JOIN item_dim_extended i ON swd.item_sk = i.i_item_sk
  WHERE (swd.quantity > 0 OR swd.net_paid IS NOT NULL)
    AND (i.i_class IS NOT NULL OR (i.i_category IS NOT NULL AND i.i_category <> ''))
  GROUP BY swd.item_sk,
           i.i_product_name,
           i.i_category,
           i.i_brand,
           i.i_color,
           i.i_size,
           swd.channel
),
item_agg AS (
  SELECT ag.*,
         row_number() OVER (PARTITION BY channel ORDER BY total_net_paid DESC) AS rank_by_channel,
         rank() OVER (ORDER BY total_net_paid DESC) AS global_rank,
         SUM(total_net_paid) OVER (PARTITION BY item_sk) AS item_total_net_paid,
         first_value(i_product_name) OVER (PARTITION BY item_sk ORDER BY first_date_sk) AS first_sale_product_name,
         lag(total_net_paid) OVER (PARTITION BY item_sk ORDER BY last_date_sk) AS prev_net_paid,
         COALESCE(total_net_profit, 0) / NULLIF(total_net_paid, 0) AS profit_margin
  FROM aggregated_sales ag
),
returns_union AS (
  SELECT cr_order_number AS order_id,
         cr_item_sk AS item_sk,
         cr_returned_date_sk AS date_sk,
         cr_return_quantity AS quantity,
         cr_return_amount AS return_amount,
         cr_net_loss AS net_loss,
         'catalog' AS channel
  FROM catalog_returns
  UNION ALL
  SELECT sr_ticket_number AS order_id,
         sr_item_sk AS item_sk,
         sr_returned_date_sk AS date_sk,
         sr_return_quantity AS quantity,
         sr_return_amt AS return_amount,
         sr_net_loss AS net_loss,
         'store' AS channel
  FROM store_returns
  UNION ALL
  SELECT wr_order_number AS order_id,
         wr_item_sk AS item_sk,
         wr_returned_date_sk AS date_sk,
         wr_return_quantity AS quantity,
         wr_return_amt AS return_amount,
         wr_net_loss AS net_loss,
         'web' AS channel
  FROM web_returns
),
items_with_returns AS (
  SELECT DISTINCT ru.item_sk
  FROM returns_union ru
),
items_sales_no_returns AS (
  SELECT DISTINCT item_sk FROM sales_union
  EXCEPT
  SELECT DISTINCT item_sk FROM items_with_returns
),
call_center_sales AS (
  SELECT cs.channel,
         SUM(cs.total_net_paid) AS total_net_paid,
         cc.cc_name,
         cc.cc_manager,
         cc.cc_tax_percentage,
         COALESCE(cc.cc_tax_percentage, 0) * SUM(cs.total_net_paid) / 100.0 AS tax_amount_estimate,
         CASE WHEN cc.cc_manager IS NULL THEN 'NO_MANAGER' ELSE cc.cc_manager END AS manager_filled
  FROM (
    SELECT channel, total_net_paid
    FROM item_agg
  ) cs
  LEFT JOIN call_center cc ON LOWER(cc.cc_class) = cs.channel
  GROUP BY cs.channel, cc.cc_name, cc.cc_manager, cc.cc_tax_percentage
),
final_result AS (
  SELECT ia.item_sk,
         ia.i_product_name,
         ia.i_category,
         ia.i_brand,
         ia.i_color,
         ia.i_size,
         ia.channel,
         ia.total_net_paid,
         ia.total_net_profit,
         ia.sales_cnt,
         ia.avg_net_paid,
         ia.max_net_paid,
         ia.min_net_paid,
         ia.rank_by_channel,
         ia.global_rank,
         ia.item_total_net_paid,
         ia.first_sale_product_name,
         ia.prev_net_paid,
         ia.profit_margin,
         CASE WHEN EXISTS (SELECT 1 FROM returns_union ru WHERE ru.item_sk = ia.item_sk AND ru.channel = ia.channel) THEN 'HAS_RETURNS' ELSE 'NO_RETURNS' END AS return_flag,
         ccs.tax_amount_estimate,
         ccs.manager_filled,
         (SELECT MAX(d.d_year) FROM date_dim d WHERE d.d_date_sk = ia.last_date_sk) AS last_year_sold,
         (SELECT COUNT(*) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = ia.item_sk AND cs2.cs_net_paid > ia.avg_net_paid) AS count_higher_than_avg,
         SUBSTRING(ia.i_product_name, 1, 10) AS product_name_prefix,
         REPLACE(ia.i_brand, ' ', '') || '_' || REPLACE(ia.i_color, ' ', '') AS brand_color_concat
  FROM item_agg ia
  LEFT JOIN call_center_sales ccs ON ia.channel = ccs.channel
  LEFT JOIN items_sales_no_returns isnr ON ia.item_sk = isnr.item_sk
)
SELECT *
FROM final_result
WHERE (tax_amount_estimate > 0 OR return_flag = 'HAS_RETURNS')
  AND (global_rank <= 10 OR manager_filled = 'NO_MANAGER')
ORDER BY channel, total_net_paid DESC
LIMIT 100

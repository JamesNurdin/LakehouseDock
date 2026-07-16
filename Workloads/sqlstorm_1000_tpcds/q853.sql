WITH date_range AS (
   SELECT d_date_sk,
          d_date,
          d_day_name
   FROM date_dim
   WHERE d_year BETWEEN 1999 AND 2000
),
channels AS (
   SELECT 'catalog' AS channel UNION ALL SELECT 'store' UNION ALL SELECT 'web'
),
date_item_channel_grid AS (
   SELECT dr.d_date_sk,
          dr.d_date,
          dr.d_day_name,
          i.i_item_sk,
          i.i_item_id,
          i.i_product_name,
          i.i_brand,
          i.i_category,
          i.i_class,
          ch.channel
   FROM date_range dr
   CROSS JOIN item i
   CROSS JOIN channels ch
),
sales_all AS (
   SELECT cs_sold_date_sk AS date_sk,
          cs_item_sk AS item_sk,
          cs_quantity AS qty,
          cs_net_paid AS net_paid,
          cs_net_profit AS net_profit,
          'catalog' AS channel,
          cs_promo_sk AS promo_sk
   FROM catalog_sales
   WHERE cs_sold_date_sk IN (SELECT d_date_sk FROM date_range)
   UNION ALL
   SELECT ss_sold_date_sk, ss_item_sk, ss_quantity, ss_net_paid, ss_net_profit, 'store', ss_promo_sk
   FROM store_sales
   WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_range)
   UNION ALL
   SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_paid, ws_net_profit, 'web', ws_promo_sk
   FROM web_sales
   WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_range)
),
returns_all AS (
   SELECT cr_returned_date_sk AS date_sk,
          cr_item_sk AS item_sk,
          -cr_return_quantity AS qty,
          -cr_return_amount AS net_paid,
          -cr_net_loss AS net_profit,
          'catalog' AS channel,
          NULL AS promo_sk
   FROM catalog_returns
   WHERE cr_returned_date_sk IN (SELECT d_date_sk FROM date_range)
   UNION ALL
   SELECT sr_returned_date_sk, sr_item_sk, -sr_return_quantity, -sr_return_amt, -sr_net_loss, 'store', NULL
   FROM store_returns
   WHERE sr_returned_date_sk IN (SELECT d_date_sk FROM date_range)
   UNION ALL
   SELECT wr_returned_date_sk, wr_item_sk, -wr_return_quantity, -wr_return_amt, -wr_net_loss, 'web', NULL
   FROM web_returns
   WHERE wr_returned_date_sk IN (SELECT d_date_sk FROM date_range)
),
combined AS (
   SELECT * FROM sales_all
   UNION ALL
   SELECT * FROM returns_all
),
daily_item_channel_agg AS (
   SELECT
      g.d_date_sk,
      g.d_date,
      g.d_day_name,
      g.i_item_sk,
      g.i_item_id,
      g.i_product_name,
      g.i_brand,
      g.i_category,
      g.i_class,
      g.channel,
      COALESCE(SUM(c.qty), 0) AS total_qty,
      COALESCE(SUM(c.net_paid), 0) AS total_net_paid,
      COALESCE(SUM(c.net_profit), 0) AS total_net_profit
   FROM date_item_channel_grid g
   LEFT JOIN combined c
      ON c.date_sk = g.d_date_sk
     AND c.item_sk = g.i_item_sk
     AND c.channel = g.channel
   GROUP BY
      g.d_date_sk,
      g.d_date,
      g.d_day_name,
      g.i_item_sk,
      g.i_item_id,
      g.i_product_name,
      g.i_brand,
      g.i_category,
      g.i_class,
      g.channel
),
channel_daily_rank AS (
   SELECT
      d.*,
      ROW_NUMBER() OVER (PARTITION BY d_date, channel ORDER BY total_net_profit DESC) AS profit_rank,
      SUM(total_net_profit) OVER (PARTITION BY i_item_id ORDER BY d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS profit_7day_moving_sum,
      AVG(total_net_profit) OVER (PARTITION BY i_item_id) AS avg_item_profit_all_time
   FROM daily_item_channel_agg d
),
store_top_items AS (
   SELECT d_date, i_item_id, profit_rank
   FROM channel_daily_rank
   WHERE channel = 'store' AND profit_rank <= 3
),
web_top_items AS (
   SELECT d_date, i_item_id, profit_rank
   FROM channel_daily_rank
   WHERE channel = 'web' AND profit_rank <= 3
),
common_top_items AS (
   SELECT i_item_id
   FROM store_top_items
   INTERSECT
   SELECT i_item_id
   FROM web_top_items
),
final AS (
   SELECT
      cri.d_date,
      cri.d_day_name,
      CASE WHEN cri.d_day_name IN ('Saturday', 'Sunday') THEN 'Weekend' ELSE 'Weekday' END AS day_type,
      cri.i_item_id,
      CONCAT(cri.i_product_name, ' (', cri.i_brand, ')') AS full_product_name,
      cri.channel,
      cri.total_qty,
      CASE WHEN cri.total_qty > 100 THEN 'High volume' ELSE 'Low volume' END AS volume_category,
      cri.total_net_paid,
      cri.total_net_profit,
      cri.profit_rank,
      cri.profit_7day_moving_sum,
      cri.avg_item_profit_all_time,
      CASE
         WHEN cri.total_net_profit > cri.avg_item_profit_all_time THEN 'Above Avg' ELSE 'Below Avg'
      END AS profit_category,
      CASE
         WHEN cri.i_item_id IN (SELECT i_item_id FROM common_top_items) THEN 'Common Top' ELSE 'Other'
      END AS top_common_flag,
      COALESCE((
         SELECT MAX(p.p_discount_active)
         FROM promotion p
         WHERE p.p_item_sk = cri.i_item_sk
           AND p.p_start_date_sk <= cri.d_date_sk
           AND p.p_end_date_sk >= cri.d_date_sk
      ), 'N/A') AS active_discount_flag,
      COALESCE((
         SELECT SUM(s2.total_qty)
         FROM daily_item_channel_agg s2
         WHERE s2.i_item_id = cri.i_item_id
      ), 0) AS total_qty_all_days,
      (SELECT COUNT(DISTINCT d2.d_date)
       FROM daily_item_channel_agg d2
       WHERE d2.i_item_id = cri.i_item_id
         AND d2.channel = cri.channel
         AND d2.total_qty > 0) AS active_days_in_channel
   FROM channel_daily_rank cri
   WHERE cri.profit_rank <= 5
)
SELECT *
FROM final
ORDER BY d_date DESC, channel, profit_rank

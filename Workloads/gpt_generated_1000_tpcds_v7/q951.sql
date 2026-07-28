WITH
  ws_agg AS (
    SELECT ws_item_sk,
           SUM(ws_net_profit) AS total_sales_profit
    FROM web_sales
    WHERE ws_quantity > 0
    GROUP BY ws_item_sk
  ),
  sr_agg AS (
    SELECT sr_item_sk,
           SUM(sr_net_loss) AS total_return_loss
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_item_sk
  ),
  ws_key AS (
    SELECT ws_item_sk,
           ws_bill_cdemo_sk,
           ws_promo_sk,
           ws_ship_mode_sk,
           ws_web_page_sk,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_quantity > 0
  )
SELECT
  i.i_item_sk,
  i.i_product_name,
  i.i_category,
  i.i_category_id,
  cd.cd_gender,
  sm.sm_code,
  wp.wp_link_count,
  ws_agg.total_sales_profit,
  sr_agg.total_return_loss,
  (ws_agg.total_sales_profit - COALESCE(sr_agg.total_return_loss, 0)) AS net_contribution,
  RANK() OVER (PARTITION BY i.i_category ORDER BY (ws_agg.total_sales_profit - COALESCE(sr_agg.total_return_loss, 0)) DESC) AS category_rank
FROM ws_key wk
JOIN ws_agg ON ws_agg.ws_item_sk = wk.ws_item_sk
LEFT JOIN sr_agg ON sr_agg.sr_item_sk = wk.ws_item_sk
JOIN item i ON i.i_item_sk = wk.ws_item_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = wk.ws_bill_cdemo_sk
JOIN promotion p ON p.p_promo_sk = wk.ws_promo_sk
JOIN ship_mode sm ON sm.sm_ship_mode_sk = wk.ws_ship_mode_sk
JOIN web_page wp ON wp.wp_web_page_sk = wk.ws_web_page_sk
WHERE wk.rn = 1
  AND i.i_category_id = 7
  AND sm.sm_code = 'AIR'
  AND i.i_rec_end_date > DATE '2000-01-01'
  AND wp.wp_link_count > 10
ORDER BY net_contribution DESC
LIMIT 100

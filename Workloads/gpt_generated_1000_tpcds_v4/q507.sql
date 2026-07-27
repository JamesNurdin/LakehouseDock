WITH
  store_agg AS (
    SELECT
      ss_item_sk,
      ss_addr_sk,
      SUM(ss_quantity) AS store_qty,
      SUM(ss_net_paid) AS store_net_paid,
      SUM(ss_net_profit) AS store_net_profit
    FROM store_sales
    WHERE ss_quantity > 0
      AND ss_net_paid > 0
      AND ss_net_profit IS NOT NULL
    GROUP BY ss_item_sk, ss_addr_sk
  ),
  web_agg AS (
    SELECT
      ws_item_sk,
      ws_ship_addr_sk,
      ws_ship_mode_sk,
      SUM(ws_quantity) AS web_qty,
      SUM(ws_net_paid) AS web_net_paid,
      SUM(ws_net_profit) AS web_net_profit,
      AVG(ws_coupon_amt) AS avg_coupon_amt,
      MAX(ws_net_paid_inc_tax) AS max_net_paid_inc_tax
    FROM web_sales
    WHERE ws_quantity > 0
      AND ws_coupon_amt > 0
      AND ws_net_paid_inc_tax > 100
    GROUP BY ws_item_sk, ws_ship_addr_sk, ws_ship_mode_sk
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  ca.ca_state,
  ca.ca_city,
  sm.sm_carrier,
  sm.sm_contract,
  p.p_promo_name,
  store_agg.store_qty,
  web_agg.web_qty,
  (store_agg.store_net_paid + web_agg.web_net_paid) AS total_net_paid,
  (store_agg.store_net_profit + web_agg.web_net_profit) AS total_net_profit,
  ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY (store_agg.store_net_profit + web_agg.web_net_profit) DESC) AS state_profit_rank,
  RANK() OVER (ORDER BY (store_agg.store_net_profit + web_agg.web_net_profit) DESC) AS global_profit_rank,
  CASE
    WHEN sm.sm_carrier = 'DHL' THEN 'Fast'
    WHEN sm.sm_carrier = 'BOXBUNDLES' THEN 'Bulk'
    ELSE 'Other'
  END AS carrier_category
FROM store_agg
JOIN web_agg
  ON store_agg.ss_item_sk = web_agg.ws_item_sk
 AND store_agg.ss_addr_sk = web_agg.ws_ship_addr_sk
JOIN item i
  ON store_agg.ss_item_sk = i.i_item_sk
JOIN customer_address ca
  ON store_agg.ss_addr_sk = ca.ca_address_sk
JOIN ship_mode sm
  ON web_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON i.i_item_sk = p.p_item_sk
WHERE ca.ca_state IN ('CA', 'TX', 'NY')
  AND ca.ca_country = 'United States'
  AND sm.sm_carrier IN ('DHL', 'BOXBUNDLES', 'ALLIANCE')
  AND p.p_channel_press = 'N'
  AND p.p_discount_active = 'Y'
  AND i.i_current_price > 10
ORDER BY total_net_profit DESC
LIMIT 100

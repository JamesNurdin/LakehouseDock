WITH sr_agg AS (
   SELECT
       sr.sr_item_sk,
       sr.sr_store_sk,
       SUM(sr.sr_return_quantity) AS total_return_qty,
       SUM(sr.sr_return_amt) AS total_return_amt,
       COUNT(DISTINCT sr.sr_reason_sk) AS distinct_reason_cnt
   FROM store_returns sr
   WHERE sr.sr_return_quantity > 0
   GROUP BY sr.sr_item_sk, sr.sr_store_sk
),
ws_agg AS (
   SELECT
       ws.ws_item_sk,
       ws.ws_bill_customer_sk,
       ws.ws_ship_mode_sk,
       ws.ws_web_page_sk,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_quantity) AS total_quantity
   FROM web_sales ws
   WHERE ws.ws_ext_sales_price > 200
     AND ws.ws_coupon_amt < 500
   GROUP BY ws.ws_item_sk, ws.ws_bill_customer_sk, ws.ws_ship_mode_sk, ws.ws_web_page_sk
)
SELECT
   i.i_item_id,
   i.i_product_name,
   i.i_current_price,
   s.s_store_name,
   c.c_first_name,
   c.c_last_name,
   ca.ca_state,
   cd.cd_gender,
   hd.hd_buy_potential,
   inv.inv_quantity_on_hand,
   p.p_promo_name,
   sm.sm_type AS ship_type,
   wp.wp_url,
   sr_agg.total_return_qty,
   sr_agg.total_return_amt,
   ws_agg.total_sales,
   ws_agg.total_quantity,
   (sr_agg.total_return_amt / NULLIF(ws_agg.total_sales, 0)) AS return_to_sales_ratio,
   sr_agg.distinct_reason_cnt
FROM sr_agg
JOIN store s ON sr_agg.sr_store_sk = s.s_store_sk
JOIN item i ON sr_agg.sr_item_sk = i.i_item_sk
JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
JOIN promotion p ON i.i_item_sk = p.p_item_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN ws_agg ON ws_agg.ws_item_sk = i.i_item_sk
JOIN customer c ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
WHERE i.i_current_price BETWEEN 20 AND 100
  AND ca.ca_state IN ('CA', 'WA', 'TN')
  AND cd.cd_gender = 'M'
  AND hd.hd_buy_potential = 'HIGH'
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
          AND p2.p_cost < 50
      )
ORDER BY return_to_sales_ratio DESC
LIMIT 100

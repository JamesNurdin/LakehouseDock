WITH agg_sales AS (
  SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_brand_id,
    i.i_class_id,
    sm.sm_type AS ship_mode_type,
    p.p_promo_name AS promo_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer cu ON ws.ws_bill_customer_sk = cu.c_customer_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
  GROUP BY i.i_item_sk, i.i_product_name, i.i_brand_id, i.i_class_id, sm.sm_type, p.p_promo_name
),
items_in_both_returns AS (
  SELECT sr.sr_item_sk AS item_sk
  FROM store_returns sr
  WHERE sr.sr_return_quantity > 2
  INTERSECT
  SELECT wr.wr_item_sk AS item_sk
  FROM web_returns wr
  WHERE wr.wr_return_quantity > 2
)
SELECT
  a.i_item_sk,
  a.i_product_name,
  a.i_brand_id,
  a.i_class_id,
  a.ship_mode_type,
  a.promo_name,
  a.total_sales,
  a.total_profit,
  a.sales_cnt,
  sr.sr_return_amt,
  sr.sr_return_tax,
  DENSE_RANK() OVER (ORDER BY a.total_profit DESC) AS profit_rank,
  ROW_NUMBER() OVER (PARTITION BY hd.hd_vehicle_count ORDER BY a.total_sales DESC) AS sales_rank_by_vehicle,
  CASE
    WHEN a.ship_mode_type = 'AIR' THEN 'Fast'
    WHEN a.ship_mode_type = 'GROUND' THEN 'Slow'
    ELSE 'Other'
  END AS shipping_speed_category
FROM agg_sales a
JOIN items_in_both_returns ib ON a.i_item_sk = ib.item_sk
JOIN store_returns sr ON sr.sr_item_sk = a.i_item_sk
JOIN customer cu ON sr.sr_customer_sk = cu.c_customer_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE a.i_brand_id IN (2002002, 8015002, 1002001)
  AND hd.hd_buy_potential = '1001-5000'
  AND a.ship_mode_type = 'AIR'
  AND EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_item_sk = a.i_item_sk
      AND cc.cc_state = 'CA'
      AND cc.cc_rec_start_date < DATE '2000-01-01'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_item_sk = a.i_item_sk
      AND wr.wr_net_loss > 0
  )
ORDER BY a.total_profit DESC
LIMIT 100

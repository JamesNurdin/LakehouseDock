WITH intersect_items AS (
   SELECT ws_item_sk AS i_item_sk
   FROM tpcds.web_sales
   INTERSECT
   SELECT cr_item_sk
   FROM tpcds.catalog_returns
),
sample_ws AS (
   SELECT *
   FROM tpcds.web_sales
   TABLESAMPLE BERNOULLI (10)
)
SELECT
   cc.cc_name,
   cp.cp_department,
   hd_bill.hd_buy_potential,
   CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Full Price' END AS promo_type,
   SUM(ws.ws_net_profit) AS total_net_profit,
   SUM(ws.ws_ext_sales_price) AS total_sales,
   COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
   ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
FROM sample_ws ws
JOIN intersect_items ii
  ON ws.ws_item_sk = ii.i_item_sk
JOIN tpcds.item i1
  ON ws.ws_item_sk = i1.i_item_sk
JOIN tpcds.promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.item i2
  ON p.p_item_sk = i2.i_item_sk
JOIN tpcds.household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_item_sk = i1.i_item_sk
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.store_returns sr
  ON sr.sr_item_sk = i1.i_item_sk
JOIN tpcds.household_demographics hd_store
  ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
WHERE NOT EXISTS (
   SELECT 1
   FROM tpcds.catalog_returns cr2
   WHERE cr2.cr_order_number = ws.ws_order_number
)
GROUP BY
   cc.cc_name,
   cp.cp_department,
   hd_bill.hd_buy_potential,
   CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Full Price' END
ORDER BY total_net_profit DESC
LIMIT 100

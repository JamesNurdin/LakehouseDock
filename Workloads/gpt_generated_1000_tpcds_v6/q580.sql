WITH item_sales AS (
  SELECT
    i.i_item_sk,
    i.i_category,
    i.i_product_name,
    cc.cc_name,
    p.p_promo_name,
    w.w_warehouse_name,
    ca.ca_city,
    cd.cd_gender,
    SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
    SUM(cs.cs_coupon_amt) AS total_catalog_coupons,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
    SUM(ws.ws_coupon_amt) AS total_web_coupons,
    SUM(wr.wr_fee) AS total_web_return_fees,
    SUM(sr.sr_fee) AS total_store_return_fees,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
  FROM item i
  LEFT JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN call_center cc
    ON cc.cc_call_center_sk = cs.cs_call_center_sk
  LEFT JOIN promotion p
    ON p.p_promo_sk = cs.cs_promo_sk
  LEFT JOIN warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
  LEFT JOIN customer c
    ON c.c_customer_sk = cs.cs_bill_customer_sk
  LEFT JOIN customer_address ca
    ON ca.ca_address_sk = c.c_current_addr_sk
  LEFT JOIN customer_demographics cd
    ON cd.cd_demo_sk = c.c_current_cdemo_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
  LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
  LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
  LEFT JOIN web_site we
    ON we.web_site_sk = ws.ws_web_site_sk
  WHERE
    cc.cc_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND inv.inv_quantity_on_hand < 100
    AND cs.cs_net_paid_inc_tax > 1000
    AND wr.wr_fee > 30
    AND i.i_current_price BETWEEN 100 AND 5000
  GROUP BY
    i.i_item_sk,
    i.i_category,
    i.i_product_name,
    cc.cc_name,
    p.p_promo_name,
    w.w_warehouse_name,
    ca.ca_city,
    cd.cd_gender
)
SELECT
  isales.i_category,
  isales.i_product_name,
  isales.cc_name,
  isales.p_promo_name,
  isales.w_warehouse_name,
  isales.ca_city,
  isales.cd_gender,
  isales.total_catalog_sales,
  isales.total_web_sales,
  isales.total_catalog_coupons,
  isales.total_web_return_fees,
  isales.total_store_return_fees,
  (SELECT MAX(cs2.cs_net_paid_inc_tax)
   FROM catalog_sales cs2
   WHERE cs2.cs_item_sk = isales.i_item_sk) AS max_catalog_sale_per_item,
  (SELECT COUNT(*)
   FROM store_returns sr2
   WHERE sr2.sr_item_sk = isales.i_item_sk) AS store_return_count
FROM item_sales isales
ORDER BY isales.total_catalog_sales DESC
LIMIT 100

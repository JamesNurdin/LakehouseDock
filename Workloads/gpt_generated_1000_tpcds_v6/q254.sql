WITH item_sales AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    i.i_class_id,
    i.i_size,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    MAX(ws.ws_net_paid_inc_ship_tax) AS max_paid
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE ws.ws_net_paid_inc_ship_tax > 1000
    AND i.i_class_id = 10
    AND i.i_size = 'economy'
    AND p.p_discount_active = 'Y'
  GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_class_id, i.i_size
),

inventory_agg AS (
  SELECT
    inv.inv_item_sk,
    SUM(inv.inv_quantity_on_hand) AS total_on_hand
  FROM inventory inv
  GROUP BY inv.inv_item_sk
),

returns_agg AS (
  SELECT
    cr.cr_item_sk,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  WHERE cr.cr_return_amount > 0
    AND cr.cr_return_quantity > 0
  GROUP BY cr.cr_item_sk
),

cr_detail AS (
  SELECT
    cr.cr_item_sk,
    MIN(cr.cr_refunded_customer_sk) AS refunded_cust_sk,
    MIN(cr.cr_refunded_addr_sk) AS refunded_addr_sk,
    MIN(cr.cr_call_center_sk) AS cc_sk
  FROM catalog_returns cr
  GROUP BY cr.cr_item_sk
)

SELECT
  s.i_item_id,
  s.i_product_name,
  s.i_class_id,
  s.i_size,
  cc.cc_name,
  COALESCE(iag.total_on_hand, 0) AS total_on_hand,
  s.total_sales,
  s.total_profit,
  s.orders,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  COALESCE(r.return_cnt, 0) AS return_cnt,
  (s.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales_after_returns
FROM item_sales s
LEFT JOIN inventory_agg iag ON s.i_item_sk = iag.inv_item_sk
LEFT JOIN returns_agg r ON s.i_item_sk = r.cr_item_sk
JOIN cr_detail cd ON s.i_item_sk = cd.cr_item_sk
JOIN call_center cc ON cd.cc_sk = cc.cc_call_center_sk
JOIN customer c_ref ON cd.refunded_cust_sk = c_ref.c_customer_sk
JOIN customer_address ca_ref ON cd.refunded_addr_sk = ca_ref.ca_address_sk
WHERE EXISTS (
  SELECT 1
  FROM promotion p_sub
  WHERE p_sub.p_item_sk = s.i_item_sk
    AND p_sub.p_discount_active = 'Y'
)
ORDER BY net_sales_after_returns DESC
LIMIT 100

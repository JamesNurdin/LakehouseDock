WITH base AS (
  SELECT
    cc.cc_state,
    cc.cc_gmt_offset,
    cp.cp_department,
    p.p_channel_radio,
    p.p_channel_dmail,
    p.p_discount_active,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    cs.cs_order_number,
    cs.cs_net_paid_inc_ship_tax,
    ws.ws_quantity,
    ws.ws_net_paid,
    cr.cr_return_amount,
    cr.cr_return_quantity
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_call_center_sk = cc.cc_call_center_sk
   AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN web_sales ws
    ON ws.ws_promo_sk = p.p_promo_sk
  WHERE cc.cc_state = 'CA'
    AND cc.cc_gmt_offset = -8.00
    AND cp.cp_department = 'Electronics'
    AND p.p_channel_radio = 'N'
    AND p.p_channel_dmail = 'Y'
    AND cs.cs_net_paid_inc_ship_tax > 2000
    AND ws.ws_quantity > 5
    AND cr.cr_return_quantity > 0
)
SELECT
  cc_state,
  cp_department,
  promo_status,
  SUM(cs_net_paid_inc_ship_tax) AS total_sales,
  AVG(ws_net_paid) AS avg_web_net,
  COUNT(DISTINCT cs_order_number) AS order_cnt,
  MIN(cr_return_amount) AS min_return,
  MAX(cr_return_amount) AS max_return
FROM base
GROUP BY ROLLUP (cc_state, cp_department, promo_status)
HAVING SUM(cs_net_paid_inc_ship_tax) > 10000
ORDER BY
  cc_state,
  cp_department,
  total_sales DESC
LIMIT 100

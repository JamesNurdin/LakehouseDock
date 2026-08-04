WITH exclusive_catalog_orders AS (
  SELECT cr.cr_order_number AS order_number
  FROM catalog_returns cr
  WHERE cr.cr_return_quantity > 0
  EXCEPT
  SELECT wr.wr_order_number
  FROM web_returns wr
  WHERE wr.wr_return_quantity > 0
),
joined_all AS (
  SELECT
    cs.cs_order_number,
    cc.cc_name,
    cc.cc_state,
    i.i_category,
    i.i_manager_id,
    p.p_promo_name,
    sm.sm_type,
    cd.cd_gender,
    ca.ca_state AS cust_state,
    wp.wp_type,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cr.cr_return_quantity,
    cr.cr_net_loss,
    wr.wr_return_quantity,
    wr.wr_net_loss
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  JOIN web_returns wr ON wr.wr_order_number = cs.cs_order_number
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE cc.cc_state = 'CA'
    AND i.i_category = 'Electronics'
    AND p.p_discount_active = 'Y'
    AND i.i_manager_id IN (64, 44)
    AND cs.cs_order_number IN (SELECT order_number FROM exclusive_catalog_orders)
)
SELECT
  cc_name,
  i_category,
  p_promo_name,
  sm_type,
  cd_gender,
  cust_state,
  SUM(cs_quantity) AS total_quantity_sold,
  SUM(cs_net_paid) AS total_net_paid,
  AVG(cs_net_profit) AS avg_net_profit,
  SUM(cr_return_quantity) AS total_catalog_returns,
  SUM(wr_return_quantity) AS total_web_returns,
  COUNT(DISTINCT cs_order_number) AS distinct_orders
FROM joined_all
GROUP BY
  cc_name,
  i_category,
  p_promo_name,
  sm_type,
  cd_gender,
  cust_state
ORDER BY total_net_paid DESC
LIMIT 100

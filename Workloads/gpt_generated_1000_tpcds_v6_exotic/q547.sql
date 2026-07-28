WITH base_sales AS (
  SELECT
    c.c_customer_id,
    i.i_item_id,
    d_ss.d_year AS sales_year,
    ss.ss_net_paid AS store_net_paid,
    ss.ss_net_profit AS store_net_profit,
    ws.ws_net_paid AS web_net_paid,
    ws.ws_net_profit AS web_net_profit,
    ca.ca_state AS customer_state,
    w.w_warehouse_id,
    sm.sm_ship_mode_id,
    wp.wp_web_page_id,
    website.web_site_id,
    inv.inv_quantity_on_hand AS inventory_qty,
    inv_prev.inv_quantity_on_hand AS inventory_qty_prev,
    d_cc_open.d_date AS cc_open_date,
    d_cc_closed.d_date AS cc_closed_date
  FROM store_sales ss
  JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN date_dim d_ws
    ON ws.ws_sold_date_sk = d_ws.d_date_sk
  JOIN item i_ws
    ON ws.ws_item_sk = i_ws.i_item_sk
  JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site website
    ON ws.ws_web_site_sk = website.web_site_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
  JOIN inventory inv_prev
    ON inv_prev.inv_item_sk = i.i_item_sk
  JOIN date_dim d_prev
    ON inv_prev.inv_date_sk = d_prev.d_date_sk
  JOIN call_center cc
    ON 1 = 1
  JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
  JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
  WHERE NOT EXISTS (
    SELECT 1
    FROM promotion p_ex
    WHERE p_ex.p_promo_sk = ss.ss_promo_sk
      AND p_ex.p_discount_active = 'Y'
  )
)
SELECT
  c_customer_id,
  i_item_id,
  sales_year,
  SUM(store_net_paid) AS total_store_net_paid,
  SUM(store_net_profit) AS total_store_net_profit,
  SUM(web_net_paid) AS total_web_net_paid,
  SUM(web_net_profit) AS total_web_net_profit,
  MAX(customer_state) AS customer_state,
  MAX(w_warehouse_id) AS warehouse_id,
  MAX(sm_ship_mode_id) AS ship_mode_id,
  MAX(wp_web_page_id) AS web_page_id,
  MAX(web_site_id) AS website_id,
  MAX(inventory_qty) AS inventory_qty,
  MAX(inventory_qty_prev) AS inventory_qty_prev,
  MAX(cc_open_date) AS call_center_open_date,
  MAX(cc_closed_date) AS call_center_closed_date,
  ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY sales_year DESC) AS rn
FROM base_sales
GROUP BY c_customer_id, i_item_id, sales_year
HAVING SUM(store_net_paid) > 1000
ORDER BY total_store_net_paid DESC
LIMIT 100

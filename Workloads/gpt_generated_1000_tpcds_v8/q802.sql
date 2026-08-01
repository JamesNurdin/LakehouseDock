WITH
store_enriched AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    t.t_hour,
    i.i_item_sk,
    i.i_product_name,
    ss.ss_quantity AS store_qty,
    ss.ss_net_paid,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state AS cust_state,
    cd.cd_gender,
    hd.hd_income_band_sk,
    s.s_store_name,
    p.p_promo_name,
    p.p_discount_active
  FROM store_sales ss
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN "store" s
    ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_promo_sk = ss.ss_promo_sk
      AND p2.p_discount_active = 'Y'
  )
),
web_enriched AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_sold_time_sk,
    t2.t_hour AS web_hour,
    i2.i_item_sk,
    i2.i_product_name,
    ws.ws_quantity AS web_qty,
    ws.ws_net_paid,
    c_bill.c_customer_sk AS bill_customer_sk,
    c_bill.c_first_name AS bill_first_name,
    ca_bill.ca_state AS bill_state,
    cd_bill.cd_gender AS bill_gender,
    ws_site.web_name,
    w.w_warehouse_name,
    p2.p_promo_name,
    ca_ship.ca_state AS ship_state
  FROM web_sales ws
  JOIN time_dim t2
    ON ws.ws_sold_time_sk = t2.t_time_sk
  JOIN item i2
    ON ws.ws_item_sk = i2.i_item_sk
  JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN promotion p2
    ON ws.ws_promo_sk = p2.p_promo_sk
),
inventory_data AS (
  SELECT
    inv.inv_item_sk,
    inv.inv_quantity_on_hand,
    w_inv.w_warehouse_name
  FROM inventory inv
  JOIN warehouse w_inv
    ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
  JOIN item i_inv
    ON inv.inv_item_sk = i_inv.i_item_sk
),
returns_data AS (
  SELECT
    wr.wr_order_number,
    wr.wr_return_quantity,
    r.r_reason_desc,
    i_ret.i_product_name,
    wr.wr_net_loss
  FROM web_returns wr
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  JOIN item i_ret
    ON wr.wr_item_sk = i_ret.i_item_sk
  JOIN web_sales ws_ret
    ON wr.wr_order_number = ws_ret.ws_order_number
),
common_items AS (
  SELECT ss.ss_item_sk AS i_item_sk FROM store_sales ss
  INTERSECT
  SELECT ws.ws_item_sk FROM web_sales ws
),
store_not_in_web AS (
  SELECT ss.ss_ticket_number FROM store_sales ss
  EXCEPT
  SELECT ws.ws_order_number FROM web_sales ws
)
SELECT
  se.i_item_sk,
  se.i_product_name,
  se.store_qty,
  we.web_qty,
  se.store_qty - we.web_qty AS qty_diff,
  se.s_store_name,
  we.web_name,
  COALESCE(se.p_promo_name, we.p_promo_name) AS promo_name,
  (SELECT MAX(ws_quantity) FROM web_sales WHERE ws_item_sk = se.i_item_sk) AS max_web_qty,
  inv.inv_quantity_on_hand,
  rd.r_reason_desc,
  cn.i_item_sk IS NOT NULL AS sold_in_both_channels,
  sn.ticket_number IS NOT NULL AS store_only_ticket
FROM store_enriched se
FULL OUTER JOIN web_enriched we
  ON se.i_item_sk = we.i_item_sk
LEFT JOIN inventory_data inv
  ON se.i_item_sk = inv.inv_item_sk
LEFT JOIN returns_data rd
  ON we.ws_order_number = rd.wr_order_number
LEFT JOIN (SELECT i_item_sk FROM common_items) cn
  ON se.i_item_sk = cn.i_item_sk
LEFT JOIN (SELECT ss_ticket_number AS ticket_number FROM store_not_in_web) sn
  ON se.ss_ticket_number = sn.ticket_number
WHERE se.cust_state = 'CA' OR we.bill_state = 'CA'
ORDER BY qty_diff DESC
LIMIT 100

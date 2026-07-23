SELECT
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    s.s_state AS store_state,
    i.i_category AS item_category,
    d_sale.d_year,
    d_sale.d_month_seq,
    p.p_promo_name,
    SUM(ss.ss_net_profit) AS total_store_sales_profit,
    SUM(ws.ws_net_profit) AS total_web_sales_profit,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(wr.wr_net_loss) AS total_web_returns_loss,
    (SUM(ss.ss_net_profit) - SUM(sr.sr_net_loss) + SUM(ws.ws_net_profit) - SUM(wr.wr_net_loss)) AS net_profit,
    (SELECT avg(inv_quantity_on_hand)
       FROM inventory inv_sub
      WHERE inv_sub.inv_item_sk = i.i_item_sk
        AND inv_sub.inv_date_sk = d_sale.d_date_sk) AS avg_inventory_qty
FROM call_center cc
JOIN date_dim d_cc
  ON cc.cc_open_date_sk = d_cc.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_cc.d_date_sk
JOIN store_sales ss
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sale
  ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c_ss
  ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN customer_address ca_ss
  ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN customer_demographics cd_ss
  ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss
  ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN income_band ib
  ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
LEFT JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_date_sk = d_sale.d_date_sk
LEFT JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN date_dim d_ws_sold
  ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
LEFT JOIN date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
LEFT JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN customer c_bill
  ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
LEFT JOIN customer c_ship
  ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
LEFT JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN customer_demographics cd_ship
  ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_item_sk = i.i_item_sk
LEFT JOIN date_dim d_wr_return
  ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
WHERE d_sale.d_year = 2001
  AND p.p_discount_active = 'Y'
  AND ib.ib_upper_bound > 50000
GROUP BY
    cc.cc_name,
    s.s_store_name,
    s.s_state,
    i.i_category,
    d_sale.d_year,
    d_sale.d_month_seq,
    p.p_promo_name,
    i.i_item_sk,
    d_sale.d_date_sk
ORDER BY net_profit DESC
LIMIT 100

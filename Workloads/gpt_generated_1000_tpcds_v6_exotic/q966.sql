WITH joined_data AS (
  SELECT
    s.s_store_name,
    i.i_brand,
    cs.cs_net_profit            AS cs_profit,
    ss.ss_net_profit            AS ss_profit,
    ws.ws_net_profit            AS ws_profit,
    cr.cr_net_loss              AS cr_loss,
    sr.sr_net_loss              AS sr_loss,
    wr.wr_net_loss              AS wr_loss,
    td_cs.t_hour                AS cs_hour,
    ca_bill.ca_state            AS bill_state,
    inv.inv_quantity_on_hand,
    i.i_current_price
  FROM catalog_sales cs
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  JOIN time_dim td_cs
    ON cs.cs_sold_time_sk = td_cs.t_time_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk

  JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
  JOIN time_dim td_ss
    ON ss.ss_sold_time_sk = td_ss.t_time_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_address ca_store
    ON ss.ss_addr_sk = ca_store.ca_address_sk
  JOIN household_demographics hd_store
    ON ss.ss_hdemo_sk = hd_store.hd_demo_sk

  JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN time_dim td_sr
    ON sr.sr_return_time_sk = td_sr.t_time_sk
  JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
  JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk

  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
  JOIN time_dim td_ws
    ON ws.ws_sold_time_sk = td_ws.t_time_sk
  JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
  JOIN customer_address ca_ws_bill
    ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
  JOIN household_demographics hd_ws_bill
    ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk

  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  JOIN time_dim td_wr
    ON wr.wr_returned_time_sk = td_wr.t_time_sk
  JOIN customer_address ca_wr_refund
    ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
  JOIN household_demographics hd_wr_refund
    ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk

  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk

  WHERE i.i_brand_id IN (6012006, 2004001)
    AND ca_bill.ca_state = 'CA'
    AND w.w_state = 'CA'
    AND td_cs.t_hour BETWEEN 8 AND 17
    AND inv.inv_quantity_on_hand > 0
)
SELECT
  jd.s_store_name,
  jd.i_brand,
  SUM(jd.cs_profit + jd.ss_profit + jd.ws_profit - jd.cr_loss - jd.sr_loss - jd.wr_loss) AS total_net_profit,
  AVG(SUM(jd.cs_profit + jd.ss_profit + jd.ws_profit - jd.cr_loss - jd.sr_loss - jd.wr_loss)) OVER (PARTITION BY jd.s_store_name) AS avg_profit_per_store,
  (
    SELECT SUM(inv2.inv_quantity_on_hand * i2.i_current_price)
    FROM inventory inv2
    JOIN item i2 ON inv2.inv_item_sk = i2.i_item_sk
    WHERE i2.i_brand_id IN (6012006, 2004001)
  ) AS total_inventory_value
FROM joined_data jd
GROUP BY jd.s_store_name, jd.i_brand
HAVING SUM(jd.cs_profit + jd.ss_profit + jd.ws_profit - jd.cr_loss - jd.sr_loss - jd.wr_loss) > 10000
ORDER BY total_net_profit DESC
LIMIT 100

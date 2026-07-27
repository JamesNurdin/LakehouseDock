WITH inv_agg AS (
        SELECT inv_item_sk,
               SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        GROUP BY inv_item_sk
    )
SELECT
    i.i_category,
    sm.sm_type,
    td_ws.t_hour,
    SUM(ws.ws_net_profit)                AS total_web_profit,
    SUM(sr.sr_net_loss)                  AS total_store_loss,
    SUM(wr.wr_net_loss)                  AS total_web_return_loss,
    SUM(inv_agg.total_qty)               AS total_inventory_qty
FROM web_sales ws
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN time_dim td_ws
  ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship
  ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_ship
  ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim td_sr
  ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN customer_demographics cd_sr
  ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN customer_address ca_sr
  ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN time_dim td_wr
  ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN customer_demographics cd_refunded
  ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_address ca_refunded
  ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_demographics cd_returning
  ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_address ca_returning
  ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN inv_agg
  ON inv_agg.inv_item_sk = i.i_item_sk
WHERE i.i_wholesale_cost > 10.00
  AND ws.ws_list_price > 50.00
GROUP BY i.i_category, sm.sm_type, td_ws.t_hour
ORDER BY total_web_profit DESC
LIMIT 100

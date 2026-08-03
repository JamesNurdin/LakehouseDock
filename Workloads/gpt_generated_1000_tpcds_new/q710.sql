WITH
  joined_all AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_quantity,
      ss.ss_ticket_number,
      ss.ss_net_paid AS store_net_paid,
      ws.ws_order_number,
      ws.ws_net_paid AS web_net_paid,
      i.i_item_id,
      p.p_promo_name,
      split(p.p_channel_details, ',') AS promo_channels,
      sm.sm_ship_mode_id,
      w.w_warehouse_name,
      d_date.d_year,
      t_time.t_hour,
      ca_bill.ca_state AS bill_state,
      ca_ship.ca_state AS ship_state,
      inv.inv_quantity_on_hand,
      wp.wp_url
    FROM catalog_sales cs
    JOIN date_dim d_date
      ON cs.cs_sold_date_sk = d_date.d_date_sk
    JOIN time_dim t_time
      ON cs.cs_sold_time_sk = t_time.t_time_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_bill
      ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship
      ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
     AND inv.inv_date_sk = d_date.d_date_sk
    JOIN store_sales ss
      ON ss.ss_sold_date_sk = d_date.d_date_sk
     AND ss.ss_item_sk = i.i_item_sk
     AND ss.ss_customer_sk = c_bill.c_customer_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d_date.d_date_sk
     AND ws.ws_item_sk = i.i_item_sk
     AND ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d_date.d_year = 2001
  ),
  channels AS (
    SELECT
      cs_order_number AS key,
      channel
    FROM joined_all
    CROSS JOIN UNNEST(promo_channels) AS t(channel)
  ),
  set_ops AS (
    SELECT cs_order_number AS key, cs_net_paid AS metric FROM joined_all
    UNION
    SELECT ss_ticket_number AS key, store_net_paid AS metric FROM joined_all
    INTERSECT
    SELECT ws_order_number AS key, web_net_paid AS metric FROM joined_all
    EXCEPT
    SELECT cs_order_number AS key, cs_net_paid AS metric FROM joined_all WHERE cs_quantity = 0
  )
SELECT
  s.key,
  s.metric,
  c.channel
FROM set_ops s
LEFT JOIN channels c
  ON s.key = c.key
WHERE s.key NOT IN (SELECT cs_order_number FROM joined_all WHERE cs_quantity < 0)
ORDER BY s.metric DESC
LIMIT 100

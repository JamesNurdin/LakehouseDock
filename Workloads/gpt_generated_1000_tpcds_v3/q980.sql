WITH
  union_orders AS (
    SELECT cs_order_number AS order_id,
           cs_warehouse_sk AS warehouse_sk
    FROM catalog_sales
    UNION ALL
    SELECT ws_order_number AS order_id,
           ws_warehouse_sk AS warehouse_sk
    FROM web_sales
  ),
  avg_warehouse_net_paid AS (
    SELECT w.w_warehouse_sk,
           AVG(cs.cs_net_paid) AS avg_cs_net_paid
    FROM warehouse w
    JOIN catalog_sales cs ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
  )
SELECT
  S.s_store_name,
  W.w_warehouse_name,
  TD.t_shift,
  COUNT(DISTINCT CS.cs_order_number)                     AS num_catalog_orders,
  SUM(CS.cs_net_paid)                                   AS total_catalog_net_paid,
  SUM(WS.ws_net_paid)                                   AS total_web_net_paid,
  SUM(SS.ss_net_paid)                                   AS total_store_net_paid,
  SUM(SR.sr_net_loss)                                   AS total_store_returns_loss,
  SUM(WR.wr_net_loss)                                   AS total_web_returns_loss,
  SUM(INV.inv_quantity_on_hand)                         AS total_inventory_on_hand,
  COUNT(DISTINCT C.c_customer_sk)                       AS num_customers,
  (
    SELECT aw.avg_cs_net_paid
    FROM avg_warehouse_net_paid aw
    WHERE aw.w_warehouse_sk = W.w_warehouse_sk
  )                                                     AS avg_catalog_net_paid_warehouse,
  (
    SELECT COUNT(*)
    FROM union_orders u
    WHERE u.warehouse_sk = W.w_warehouse_sk
  )                                                     AS total_orders_in_union
FROM store_sales SS
JOIN time_dim TD ON SS.ss_sold_time_sk = TD.t_time_sk
JOIN customer C ON SS.ss_customer_sk = C.c_customer_sk
JOIN customer_demographics CD ON SS.ss_cdemo_sk = CD.cd_demo_sk
JOIN household_demographics HD ON SS.ss_hdemo_sk = HD.hd_demo_sk
JOIN customer_address CA ON SS.ss_addr_sk = CA.ca_address_sk
JOIN store S ON SS.ss_store_sk = S.s_store_sk
LEFT JOIN store_returns SR ON SR.sr_ticket_number = SS.ss_ticket_number
                           AND SR.sr_store_sk = S.s_store_sk
JOIN catalog_sales CS ON CS.cs_sold_time_sk = TD.t_time_sk
                      AND CS.cs_bill_customer_sk = C.c_customer_sk
JOIN web_sales WS ON WS.ws_sold_time_sk = TD.t_time_sk
                  AND WS.ws_bill_customer_sk = C.c_customer_sk
JOIN web_page WP ON WS.ws_web_page_sk = WP.wp_web_page_sk
JOIN web_site WEB ON WS.ws_web_site_sk = WEB.web_site_sk
JOIN ship_mode SM ON CS.cs_ship_mode_sk = SM.sm_ship_mode_sk
JOIN warehouse W ON CS.cs_warehouse_sk = W.w_warehouse_sk
JOIN inventory INV ON INV.inv_warehouse_sk = W.w_warehouse_sk
JOIN web_returns WR ON WR.wr_order_number = WS.ws_order_number
                     AND WR.wr_item_sk = WS.ws_item_sk
WHERE
  TD.t_shift = 'first'
  AND W.w_state = 'CA'
  AND WEB.web_rec_start_date >= DATE '2000-01-01'
  AND CS.cs_quantity > 5
  AND EXISTS (
    SELECT 1
    FROM store_returns SR2
    WHERE SR2.sr_store_sk = S.s_store_sk
      AND SR2.sr_net_loss > 0
  )
  AND C.c_customer_sk IN (
    SELECT cs_bill_customer_sk FROM catalog_sales WHERE cs_quantity > 5
    UNION
    SELECT ws_bill_customer_sk FROM web_sales WHERE ws_quantity > 5
  )
GROUP BY
  S.s_store_name,
  W.w_warehouse_name,
  TD.t_shift,
  W.w_warehouse_sk
ORDER BY
  total_catalog_net_paid DESC
LIMIT 100

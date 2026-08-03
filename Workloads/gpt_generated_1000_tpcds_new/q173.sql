WITH excluded_orders AS (
    SELECT cs_order_number FROM catalog_sales
    EXCEPT
    SELECT ws_order_number FROM web_sales
)
SELECT
    i1.i_category                         AS item_category,
    cc.cc_name                            AS call_center_name,
    s.s_store_name                        AS store_name,
    cd_bill.cd_gender                     AS customer_gender,
    sm.sm_type                            AS ship_mode_type,
    sm_ws.sm_type                         AS web_ship_mode_type,
    COUNT(DISTINCT cs.cs_order_number)    AS orders_count,
    SUM(cs.cs_net_paid)                   AS total_catalog_sales,
    SUM(sr.sr_return_amt)                 AS total_store_returns,
    SUM(ws.ws_net_paid)                   AS total_web_sales,
    SUM(inv.inv_quantity_on_hand)         AS total_inventory
FROM catalog_sales cs
JOIN item i1
     ON cs.cs_item_sk = i1.i_item_sk
JOIN customer c_bill
     ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill
     ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
JOIN store_returns sr
     ON sr.sr_item_sk = i1.i_item_sk
JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
JOIN customer c_store
     ON sr.sr_customer_sk = c_store.c_customer_sk
JOIN customer_demographics cd_store
     ON sr.sr_cdemo_sk = cd_store.cd_demo_sk
JOIN inventory inv
     ON inv.inv_item_sk = i1.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
     ON ws.ws_item_sk = i1.i_item_sk
JOIN customer c_ws
     ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
JOIN ship_mode sm_ws
     ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
WHERE cs.cs_order_number IN (SELECT cs_order_number FROM excluded_orders)
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr_sub
        WHERE cr_sub.cr_returned_date_sk = cs.cs_sold_date_sk
          AND cr_sub.cr_return_amount > 100
      )
GROUP BY
    i1.i_category,
    cc.cc_name,
    s.s_store_name,
    cd_bill.cd_gender,
    sm.sm_type,
    sm_ws.sm_type
ORDER BY total_catalog_sales DESC
LIMIT 100

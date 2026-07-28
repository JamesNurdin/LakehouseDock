WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_category,
    hd.hd_buy_potential,
    COUNT(DISTINCT cs.cs_order_number)                      AS num_catalog_orders,
    SUM(cs.cs_net_paid)                                    AS catalog_sales,
    SUM(ss.ss_net_paid)                                    AS store_sales,
    SUM(ws.ws_net_paid)                                    AS web_sales,
    SUM(cr.cr_return_amount)                               AS catalog_returns_amount,
    SUM(sr.sr_return_amt)                                  AS store_returns_amount,
    SUM(inv_agg.total_on_hand)                             AS total_inventory_on_hand,
    SUM(CASE WHEN sm.sm_carrier = 'DIAMOND' THEN 1 ELSE 0 END) AS diamond_shipments
FROM catalog_sales cs
JOIN time_dim td_cs          ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN customer c_bill         ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc          ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp         ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w_cs          ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN item i                  ON cs.cs_item_sk = i.i_item_sk

-- catalog returns linked to the same order/item
JOIN catalog_returns cr       ON cr.cr_order_number = cs.cs_order_number
                              AND cr.cr_item_sk = i.i_item_sk
JOIN time_dim td_cr          ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN ship_mode sm2           ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN warehouse w_cr          ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN call_center cc2         ON cr.cr_call_center_sk = cc2.cc_call_center_sk
JOIN catalog_page cp2        ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk

-- store sales (shares item, customer, hd, time)
JOIN store_sales ss           ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim td_ss          ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN customer c_store        ON ss.ss_customer_sk = c_store.c_customer_sk
JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk

-- store returns linked to store sales
JOIN store_returns sr        ON sr.sr_item_sk = ss.ss_item_sk
                              AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim td_sr          ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN customer c_sr          ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk

-- web sales
JOIN web_sales ws            ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim td_ws          ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN customer c_ws          ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
JOIN ship_mode sm_ws        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws         ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk

-- inventory information for the warehouse used in catalog sales
JOIN inventory_agg inv_agg   ON inv_agg.inv_item_sk = i.i_item_sk
                              AND inv_agg.inv_warehouse_sk = w_cs.w_warehouse_sk
WHERE i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
  AND EXISTS (
        SELECT 1 FROM catalog_page cp_sub
        WHERE cp_sub.cp_type = 'monthly'
          AND cp_sub.cp_catalog_page_sk = cs.cs_catalog_page_sk
    )
GROUP BY CUBE(i.i_category, hd.hd_buy_potential)
ORDER BY i.i_category, hd.hd_buy_potential
LIMIT 100

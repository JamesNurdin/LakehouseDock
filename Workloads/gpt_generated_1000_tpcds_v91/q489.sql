WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    dd_sold.d_year AS year,
    s.s_city AS store_city,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold
FROM cs_sample cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim dd_sold
    ON cs.cs_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship
    ON cs.cs_ship_date_sk = dd_ship.d_date_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
    AND inv.inv_date_sk = dd_sold.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_call_center_sk = cc.cc_call_center_sk
    AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    AND cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN date_dim dd_return
    ON cr.cr_returned_date_sk = dd_return.d_date_sk
JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c_bill.c_customer_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN date_dim dd_sr_return
    ON sr.sr_returned_date_sk = dd_sr_return.d_date_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    AND ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    AND ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    AND ws.ws_ship_customer_sk = c_ship.c_customer_sk
    AND ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    AND ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim dd_ws_sold
    ON ws.ws_sold_date_sk = dd_ws_sold.d_date_sk
JOIN date_dim dd_ws_ship
    ON ws.ws_ship_date_sk = dd_ws_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
    cs.cs_ext_sales_price > (SELECT max(p_cost) FROM promotion)
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c_bill.c_customer_sk
          AND sr2.sr_net_loss > 0
    )
GROUP BY
    dd_sold.d_year,
    s.s_city

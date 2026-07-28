WITH item_inventory AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_category,
           i.i_current_price,
           w.w_warehouse_name,
           w.w_state,
           inv.inv_quantity_on_hand
    FROM item i
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
)
SELECT
    ii.i_category,
    cc.cc_name,
    cp.cp_type,
    ii.w_warehouse_name,
    r.r_reason_desc,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(wr.wr_net_loss) AS total_web_returns_loss,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(ii.inv_quantity_on_hand) AS avg_inventory_qty
FROM item_inventory ii
JOIN catalog_sales cs
    ON cs.cs_item_sk = ii.i_item_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = ii.i_item_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_sales ss
    ON ss.ss_item_sk = ii.i_item_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ii.i_item_sk
JOIN web_returns wr
    ON wr.wr_item_sk = ii.i_item_sk
WHERE
    cc.cc_employees >= 100
    AND cp.cp_type = 'promo'
    AND ii.inv_quantity_on_hand > 500
    AND ii.w_state = 'CA'
GROUP BY
    ii.i_category,
    cc.cc_name,
    cp.cp_type,
    ii.w_warehouse_name,
    r.r_reason_desc
HAVING
    SUM(cs.cs_net_paid) > 100000
ORDER BY
    total_catalog_sales DESC
LIMIT 100

WITH sales_with_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cr.cr_return_amount,
        cr.cr_reason_sk
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
)
SELECT
    cc.cc_name,
    i.i_category,
    sm.sm_type,
    COUNT(DISTINCT s.cs_order_number) AS order_cnt,
    SUM(s.cs_net_paid) AS total_sales,
    SUM(COALESCE(s.cr_return_amount, 0)) AS total_returns,
    AVG(s.cs_ext_discount_amt) AS avg_discount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    (
        SELECT AVG(inv2.inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
    ) AS avg_item_inventory
FROM sales_with_returns s
JOIN time_dim td
    ON s.cs_sold_time_sk = td.t_time_sk
JOIN customer_address ca_bill
    ON s.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON s.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN call_center cc
    ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
    ON s.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON s.cs_promo_sk = p.p_promo_sk
LEFT JOIN reason r
    ON s.cr_reason_sk = r.r_reason_sk
JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
   AND w.w_warehouse_sk = inv.inv_warehouse_sk
WHERE
    cc.cc_state = 'CA'
    AND i.i_category = 'Electronics'
    AND sm.sm_type = 'OVERNIGHT'
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = s.cs_promo_sk
          AND p2.p_channel_email = 'Y'
    )
    AND inv.inv_quantity_on_hand > 0
GROUP BY
    cc.cc_name,
    i.i_category,
    sm.sm_type,
    i.i_item_sk
ORDER BY
    total_sales DESC
LIMIT 100

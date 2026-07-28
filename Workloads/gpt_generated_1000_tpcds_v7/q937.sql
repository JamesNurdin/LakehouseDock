WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        ws.ws_net_paid AS ws_net_paid,
        cr.cr_return_amount,
        sr.sr_return_amt,
        i.i_item_id,
        i.i_product_name,
        i.i_class_id,
        i.i_formulation,
        p.p_discount_active,
        cc.cc_name,
        cc.cc_state,
        w.w_warehouse_name,
        w.w_state,
        td.t_hour,
        r.r_reason_desc,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk AND cr.cr_order_number = cs.cs_order_number
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_class_id = 7
      AND i.i_formulation LIKE '%steel%'
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND cs.cs_quantity > 5
      AND ws.ws_net_profit > 0
      AND EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = cs.cs_item_sk
              AND cr2.cr_return_amount > 1000
        )
)
SELECT
    i_item_id,
    i_product_name,
    cc_name,
    w_warehouse_name,
    t_hour,
    r_reason_desc,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_net_paid) AS total_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(cr_return_amount) AS total_catalog_returns,
    SUM(sr_return_amt) AS total_store_returns,
    AVG(cs_ext_discount_amt) AS avg_discount,
    MIN(inv_quantity_on_hand) AS min_inventory_on_hand,
    (
        SELECT AVG(cs2.cs_ext_discount_amt)
        FROM catalog_sales cs2
        JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
        WHERE i2.i_item_id = base.i_item_id
    ) AS overall_avg_discount_per_item
FROM base
GROUP BY
    i_item_id,
    i_product_name,
    cc_name,
    w_warehouse_name,
    t_hour,
    r_reason_desc
ORDER BY total_sales DESC
LIMIT 100

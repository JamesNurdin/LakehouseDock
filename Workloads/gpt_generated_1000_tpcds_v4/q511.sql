WITH inv_wh AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    sm.sm_type,
    w.w_state,
    CASE WHEN cr.cr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    inv_wh.total_qty,
    (
        SELECT AVG(cr2.cr_net_loss)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
    ) AS avg_warehouse_loss
FROM catalog_returns cr
JOIN customer cust_ref
    ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer cust_ret
    ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
JOIN household_demographics hd_ret
    ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inv_wh
    ON inv_wh.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON wp.wp_customer_sk = cust_ret.c_customer_sk
JOIN customer cust_cur
    ON wp.wp_customer_sk = cust_cur.c_customer_sk
JOIN household_demographics hd_cur
    ON cust_cur.c_current_hdemo_sk = hd_cur.hd_demo_sk
JOIN customer_address ca_cur
    ON cust_cur.c_current_addr_sk = ca_cur.ca_address_sk
WHERE sm.sm_type = 'EXPRESS'
GROUP BY
    sm.sm_type,
    w.w_state,
    CASE WHEN cr.cr_net_loss > 1000 THEN 'High' ELSE 'Low' END,
    inv_wh.total_qty,
    w.w_warehouse_sk
ORDER BY total_return_amount DESC
LIMIT 100

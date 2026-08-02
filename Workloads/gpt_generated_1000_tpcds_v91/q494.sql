WITH excluded_items AS (
    SELECT i.i_item_id
    FROM item i
    WHERE i.i_item_sk IN (SELECT inv_item_sk FROM inventory)
    EXCEPT
    SELECT i2.i_item_id
    FROM item i2
    JOIN web_sales ws ON i2.i_item_sk = ws.ws_item_sk
),
joined_data AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        i.i_item_sk AS item_sk,
        w.w_warehouse_name,
        cc.cc_name AS call_center_name,
        sm.sm_type AS ship_mode_type,
        r.r_reason_desc,
        ca_refunded.ca_state AS refunded_state,
        ca_returning.ca_state AS returning_state,
        ca_store.ca_state AS store_state,
        wp.wp_type AS web_page_type,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand,
        promo_stats.min_promo_cost
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT MIN(p.p_cost) AS min_promo_cost
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
    ) AS promo_stats
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca_store ON sr.sr_addr_sk = ca_store.ca_address_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    LEFT JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
)
SELECT
    jd.i_item_id,
    jd.i_category,
    jd.w_warehouse_name,
    SUM(COALESCE(jd.cr_net_loss, 0) + COALESCE(jd.sr_net_loss, 0) + COALESCE(jd.wr_net_loss, 0)) AS total_net_loss,
    COUNT(DISTINCT jd.cr_return_amount) AS catalog_return_txns,
    MIN(jd.min_promo_cost) AS min_promo_cost,
    (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_item_sk = jd.item_sk) AS store_return_txn_count,
    RANK() OVER (PARTITION BY jd.w_warehouse_name ORDER BY SUM(COALESCE(jd.cr_net_loss, 0) + COALESCE(jd.sr_net_loss, 0) + COALESCE(jd.wr_net_loss, 0)) DESC) AS warehouse_rank,
    CASE WHEN jd.i_item_id IN (SELECT i_item_id FROM excluded_items) THEN 'Excluded' ELSE 'Included' END AS exclusion_flag
FROM joined_data jd
GROUP BY
    jd.i_item_id,
    jd.i_category,
    jd.w_warehouse_name,
    jd.item_sk
HAVING SUM(COALESCE(jd.cr_net_loss, 0) + COALESCE(jd.sr_net_loss, 0) + COALESCE(jd.wr_net_loss, 0)) > 1000
ORDER BY total_net_loss DESC
LIMIT 100

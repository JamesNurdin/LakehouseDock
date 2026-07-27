WITH base AS (
    SELECT
        d_ret.d_date,
        i.i_item_id,
        i.i_item_sk,
        i.i_color,
        i.i_manager_id,
        ca_store.ca_state AS store_state,
        ca_refund.ca_state AS refund_state,
        r_store.r_reason_desc AS store_reason,
        r_cat.r_reason_desc AS catalog_reason,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss AS store_net_loss,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss AS catalog_net_loss,
        w.w_warehouse_name,
        cp.cp_catalog_page_number,
        p.p_promo_name,
        CASE WHEN i.i_color = 'sienna' THEN 'Sienna Item' ELSE 'Other Color' END AS color_group
    FROM store_returns sr
    JOIN catalog_returns cr
        ON sr.sr_returned_date_sk = cr.cr_returned_date_sk
        AND sr.sr_item_sk = cr.cr_item_sk
        AND sr.sr_reason_sk = cr.cr_reason_sk
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca_store
        ON sr.sr_addr_sk = ca_store.ca_address_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN reason r_store
        ON sr.sr_reason_sk = r_store.r_reason_sk
    JOIN reason r_cat
        ON cr.cr_reason_sk = r_cat.r_reason_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
        AND p.p_start_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND i.i_manager_id IN (13, 27)
      AND ca_store.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
)
SELECT
    color_group,
    i_item_id,
    d_date,
    SUM(store_net_loss) AS total_store_loss,
    SUM(catalog_net_loss) AS total_catalog_loss,
    SUM(store_net_loss + catalog_net_loss) AS total_combined_loss,
    ROW_NUMBER() OVER (PARTITION BY color_group ORDER BY SUM(store_net_loss + catalog_net_loss) DESC) AS loss_rank,
    CASE WHEN SUM(store_net_loss + catalog_net_loss) > 10000 THEN 'High Loss' ELSE 'Normal Loss' END AS loss_category,
    (SELECT AVG(cr2.cr_return_amount)
       FROM catalog_returns cr2
       WHERE cr2.cr_item_sk = base.i_item_sk) AS avg_catalog_return_amount
FROM base
GROUP BY ROLLUP (color_group, i_item_id, i_item_sk, d_date)
HAVING SUM(store_net_loss + catalog_net_loss) IS NOT NULL
ORDER BY total_combined_loss DESC
LIMIT 100

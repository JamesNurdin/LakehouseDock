WITH joined_facts AS (
    SELECT
        cr.cr_returned_date_sk,
        d.d_year,
        d.d_month_seq,
        cr.cr_item_sk AS item_sk,
        i.i_current_price AS current_price,
        i.i_product_name AS product_name,
        i.i_category_id,
        i.i_class_id,
        cr.cr_net_loss AS catalog_net_loss,
        wr.wr_net_loss AS web_net_loss,
        r.r_reason_desc,
        split(r.r_reason_desc, ' ') AS reason_words,
        cc.cc_name,
        s.s_store_id,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        -- auxiliary joins – columns not projected are kept only to satisfy join requirements
        sm.sm_ship_mode_id,
        c_refunded.c_customer_sk AS refunded_customer_sk,
        ca_refunded.ca_address_sk AS refunded_addr_sk,
        c_returning.c_customer_sk AS returning_customer_sk,
        ca_returning.ca_address_sk AS returning_addr_sk,
        c_wr_refunded.c_customer_sk AS wr_refunded_customer_sk,
        ca_wr_refunded.ca_address_sk AS wr_refunded_addr_sk
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN customer c_wr_refunded
        ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
    LEFT JOIN customer_address ca_wr_refunded
        ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
)
SELECT
    jf.d_year,
    jf.d_month_seq,
    jf.r_reason_desc,
    jf.cc_name,
    SUM(jf.catalog_net_loss + COALESCE(jf.web_net_loss, 0)) AS total_net_loss,
    AVG(jf.current_price) AS avg_item_price,
    SUM(jf.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT jf.item_sk) AS distinct_items_sold,
    CASE
        WHEN SUM(jf.catalog_net_loss + COALESCE(jf.web_net_loss, 0)) > 50000 THEN 'HIGH'
        ELSE 'LOW'
    END AS net_loss_category,
    word AS reason_word
FROM joined_facts jf
CROSS JOIN UNNEST(jf.reason_words) AS t(word)
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = jf.item_sk
      AND wr2.wr_net_loss > 0
)
GROUP BY jf.d_year, jf.d_month_seq, jf.r_reason_desc, jf.cc_name, word
ORDER BY total_net_loss DESC
LIMIT 100

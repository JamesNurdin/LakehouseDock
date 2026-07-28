WITH all_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        c.cc_call_center_sk,
        c.cc_name,
        c.cc_state,
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        sm.sm_type,
        p.p_promo_id,
        p.p_discount_active,
        inv.inv_quantity_on_hand,
        ws.web_site_id,
        ws.web_country,
        wp.wp_type,
        CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'Profit' END AS loss_indicator,
        ROW_NUMBER() OVER (
            PARTITION BY d.d_year, i.i_category
            ORDER BY cr.cr_return_amount DESC
        ) AS rn
    FROM catalog_returns cr
    INNER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN call_center c
        ON cr.cr_call_center_sk = c.cc_call_center_sk
    INNER JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_web_page_sk = wr.wr_web_page_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND c.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND ws.web_country = 'US'
)
SELECT
    cr_returned_date_sk,
    cr_return_amount,
    cr_net_loss,
    cc_name,
    cc_state,
    i_item_id,
    i_category,
    i_brand,
    d_year,
    d_month_seq,
    r_reason_desc,
    sm_type,
    p_promo_id,
    inv_quantity_on_hand,
    web_site_id,
    wp_type,
    loss_indicator,
    rn
FROM all_data
ORDER BY loss_indicator, rn
LIMIT 100

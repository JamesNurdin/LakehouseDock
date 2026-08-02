WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ws.ws_order_number,
        ws.ws_ext_tax,
        ws.ws_net_paid,
        i.i_category,
        i.i_brand,
        r.r_reason_desc,
        sm.sm_carrier,
        p.p_discount_active,
        inv.inv_quantity_on_hand,
        wp.wp_char_count,
        s.s_store_id,
        t.t_hour,
        w.w_warehouse_name
    FROM
        date_dim d
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND ws.ws_ext_tax > 30
        AND sm.sm_carrier = 'UPS'
        AND inv.inv_quantity_on_hand > 0
),
expanded AS (
    SELECT
        d_year,
        d_month_seq,
        ws_order_number,
        ws_ext_tax,
        ws_net_paid,
        i_category,
        i_brand,
        r_reason_desc,
        sm_carrier,
        p_discount_active,
        inv_quantity_on_hand,
        wp_char_count,
        s_store_id,
        t_hour,
        w_warehouse_name,
        split(r_reason_desc, ' ') AS reason_words
    FROM base
),
aggregated AS (
    SELECT
        d_year,
        i_category,
        i_brand,
        sm_carrier,
        word,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_ext_tax) AS avg_ext_tax,
        COUNT(*) AS order_cnt,
        MIN(ws_ext_tax) AS min_ext_tax,
        MAX(ws_ext_tax) AS max_ext_tax
    FROM expanded
    CROSS JOIN UNNEST(reason_words) AS t (word)
    GROUP BY d_year, i_category, i_brand, sm_carrier, word
)
SELECT
    d_year,
    i_category,
    i_brand,
    sm_carrier,
    word,
    total_net_paid,
    avg_ext_tax,
    order_cnt,
    min_ext_tax,
    max_ext_tax,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn_global
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100

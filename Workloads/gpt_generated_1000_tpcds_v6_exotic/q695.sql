WITH joined_data AS (
    SELECT DISTINCT
        cc.cc_call_center_id,
        d_sale.d_year AS sale_year,
        ws.ws_net_profit,
        cr.cr_net_loss,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        p.p_promo_name,
        wp.wp_type,
        inv.inv_quantity_on_hand
    FROM call_center cc
    JOIN catalog_returns cr
        ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd_ref.cd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd_ref.hd_demo_sk
    JOIN date_dim d_sale
        ON ws.ws_sold_date_sk = d_sale.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sale.d_date_sk
    WHERE d_sale.d_year BETWEEN 2001 AND 2002
      AND cc.cc_state = 'CA'
      AND p.p_channel_tv = 'Y'
),
agg_per_center AS (
    SELECT
        cc_call_center_id,
        sale_year,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT p_promo_name) AS distinct_promos
    FROM joined_data
    GROUP BY cc_call_center_id, sale_year
    HAVING SUM(ws_net_profit) > 10000
)
SELECT
    cc_call_center_id,
    sale_year,
    total_net_profit,
    total_net_loss,
    total_quantity,
    avg_discount,
    distinct_promos,
    (total_net_profit - total_net_loss) AS profit_margin
FROM agg_per_center
ORDER BY profit_margin DESC
LIMIT 100

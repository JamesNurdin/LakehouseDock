WITH base AS (
    SELECT
        i.i_item_id AS i_item_id,
        i.i_category AS i_category,
        d_c.d_year AS d_year,
        cs.cs_net_profit AS cs_net_profit,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_net_loss AS sr_net_loss,
        p.p_discount_active AS p_discount_active,
        sm.sm_type AS sm_type,
        cp.cp_type AS cp_type,
        wp.wp_type AS wp_type,
        CASE
            WHEN p.p_discount_active = 'Y' THEN 'Promotion'
            ELSE 'NoPromotion'
        END AS promo_flag,
        CASE
            WHEN sm.sm_type = 'AIR' THEN 'Air'
            WHEN sm.sm_type = 'RAIL' THEN 'Rail'
            ELSE 'Other'
        END AS ship_mode_group,
        (COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(cr.cr_net_loss, 0) - COALESCE(sr.sr_net_loss, 0)) AS total_net_profit
    FROM catalog_returns cr
    INNER JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    INNER JOIN item i ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    INNER JOIN date_dim d_c ON cs.cs_sold_date_sk = d_c.d_date_sk
    INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    INNER JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    INNER JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    INNER JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN customer_address ca_cr_refunded ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
    LEFT JOIN customer_address ca_cr_returning ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
    LEFT JOIN customer_demographics cd_cr_refunded ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
    LEFT JOIN customer_demographics cd_cr_returning ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
    LEFT JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    LEFT JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    LEFT JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    LEFT JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    LEFT JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    LEFT JOIN customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
    LEFT JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    LEFT JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    WHERE d_c.d_year = 2001
      AND i.i_category = 'Electronics'
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
)
SELECT
    agg.i_category AS category,
    agg.sum_total_net_profit AS sum_net_profit,
    agg.sum_total_net_profit / total.total_all AS profit_share,
    agg.avg_total_net_profit AS avg_net_profit,
    agg.distinct_items AS distinct_items
FROM (
    SELECT
        i_category,
        SUM(total_net_profit) AS sum_total_net_profit,
        AVG(total_net_profit) AS avg_total_net_profit,
        COUNT(DISTINCT i_item_id) AS distinct_items
    FROM base
    GROUP BY i_category
) agg
CROSS JOIN (
    SELECT SUM(total_net_profit) AS total_all FROM base
) total
WHERE agg.sum_total_net_profit > 100000
ORDER BY agg.sum_total_net_profit DESC
LIMIT 100

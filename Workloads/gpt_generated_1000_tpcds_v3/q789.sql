WITH sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        s.s_store_name,
        ss.ss_item_sk,
        i.i_product_name,
        i.i_color,
        i.i_manager_id,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        p.p_promo_id,
        p.p_channel_email,
        hd.hd_income_band_sk,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY ss.ss_net_paid DESC) AS rn_store_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_state = 'CA'
      AND i.i_color IN ('pink', 'royal')
      AND p.p_channel_email = 'N'
      AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
)
SELECT
    sa.s_store_name,
    sa.i_product_name,
    sa.i_color,
    sa.hd_income_band_sk,
    sa.ca_state,
    SUM(sa.ss_net_profit) AS total_net_profit,
    SUM(sa.ss_quantity) AS total_quantity,
    CASE
        WHEN SUM(sa.ss_net_profit) > 100000 THEN 'High'
        WHEN SUM(sa.ss_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (ORDER BY SUM(sa.ss_net_profit) DESC) AS profit_rank,
    DENSE_RANK() OVER (ORDER BY SUM(sa.ss_quantity) DESC) AS quantity_dense_rank
FROM sales_agg sa
JOIN catalog_sales cs ON cs.cs_item_sk = sa.ss_item_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p2 ON cs.cs_promo_sk = p2.p_promo_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = sa.ss_ticket_number
LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
GROUP BY
    sa.s_store_name,
    sa.i_product_name,
    sa.i_color,
    sa.hd_income_band_sk,
    sa.ca_state
HAVING SUM(sa.ss_net_profit) IS NOT NULL
ORDER BY profit_rank
LIMIT 100

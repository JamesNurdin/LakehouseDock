SELECT
    i.i_category,
    i.i_brand,
    COALESCE(p.p_promo_name, 'No Promotion') AS promo_name,
    t_ws.t_shift AS web_shift,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_profit,
    sr_stats.total_store_return_amount,
    sr_stats.total_store_net_loss,
    cr_stats.total_catalog_return_amount,
    cr_stats.total_catalog_net_loss
FROM item i
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
CROSS JOIN LATERAL (
    SELECT
        SUM(sr.sr_return_amt) AS total_store_return_amount,
        SUM(sr.sr_net_loss) AS total_store_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_item_sk = i.i_item_sk
) AS sr_stats
CROSS JOIN LATERAL (
    SELECT
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    WHERE cr.cr_item_sk = i.i_item_sk
) AS cr_stats
WHERE i.i_category = 'Electronics'
GROUP BY
    i.i_category,
    i.i_brand,
    COALESCE(p.p_promo_name, 'No Promotion'),
    t_ws.t_shift,
    sr_stats.total_store_return_amount,
    sr_stats.total_store_net_loss,
    cr_stats.total_catalog_return_amount,
    cr_stats.total_catalog_net_loss
ORDER BY total_web_profit DESC
LIMIT 100

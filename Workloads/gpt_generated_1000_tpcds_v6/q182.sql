WITH high_income_hh AS (
    SELECT hd.hd_demo_sk
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 80001
      AND ib.ib_upper_bound <= 180000
)
SELECT
    d.d_year,
    w.w_warehouse_name,
    SUM(sr.sr_net_loss) AS total_store_loss,
    SUM(cr.cr_net_loss) AS total_catalog_loss,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
FROM
    store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    JOIN high_income_hh hh_ret ON sr.sr_hdemo_sk = hh_ret.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_refunded_hdemo_sk = sr.sr_hdemo_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_ship_date_sk = d.d_date_sk
        AND ws.ws_bill_hdemo_sk = sr.sr_hdemo_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE
    d.d_year = 2001
    AND w.w_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND wsit.web_country = 'United States'
    AND p.p_discount_active = 'Y'
    AND EXISTS (
        SELECT 1 FROM reason r2 WHERE r2.r_reason_desc = r.r_reason_desc
    )
GROUP BY
    d.d_year,
    w.w_warehouse_name
HAVING
    SUM(ws.ws_net_profit) > (
        SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2
    )
ORDER BY
    total_web_profit DESC
LIMIT 100

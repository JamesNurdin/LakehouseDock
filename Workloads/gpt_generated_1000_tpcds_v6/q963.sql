SELECT
    s.s_store_name,
    p_ss.p_promo_name,
    sm_cr.sm_ship_mode_id,
    d_date.d_year,
    SUM(ss.ss_net_profit) AS store_sales_net_profit,
    SUM(ws.ws_net_profit) AS web_sales_net_profit,
    SUM(cr.cr_net_loss)   AS catalog_returns_net_loss,
    CASE
        WHEN SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss) > 0
            THEN 'Overall Profit'
        ELSE 'Overall Loss'
    END AS overall_status
FROM tpcds.date_dim d_date

-- store_sales and its dimensions
JOIN tpcds.store_sales ss                     ON ss.ss_sold_date_sk = d_date.d_date_sk
JOIN tpcds.time_dim t_ss                     ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN tpcds.customer_demographics cd_ss      ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN tpcds.household_demographics hd_ss     ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN tpcds.income_band ib_ss                ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk
JOIN tpcds.store s                          ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.promotion p_ss                   ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN tpcds.date_dim d_store_closed          ON s.s_closed_date_sk = d_store_closed.d_date_sk

-- catalog_returns and its dimensions
JOIN tpcds.catalog_returns cr               ON cr.cr_returned_date_sk = d_date.d_date_sk
JOIN tpcds.time_dim t_cr                     ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN tpcds.customer_demographics cd_refunded   ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN tpcds.household_demographics hd_refunded   ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN tpcds.customer_demographics cd_returning  ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN tpcds.household_demographics hd_returning  ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN tpcds.call_center cc                  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp                  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm_cr                  ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN tpcds.income_band ib_refunded          ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
JOIN tpcds.income_band ib_returning          ON hd_returning.hd_income_band_sk = ib_returning.ib_income_band_sk
JOIN tpcds.date_dim d_cc_closed             ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN tpcds.date_dim d_cc_open               ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN tpcds.date_dim d_cp_start              ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN tpcds.date_dim d_cp_end                ON cp.cp_end_date_sk = d_cp_end.d_date_sk

-- web_sales and its dimensions
JOIN tpcds.web_sales ws                     ON ws.ws_sold_date_sk = d_date.d_date_sk
JOIN tpcds.time_dim t_ws                     ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN tpcds.date_dim d_ws_ship                ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN tpcds.customer_demographics cd_bill    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.household_demographics hd_bill   ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.customer_demographics cd_ship    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN tpcds.household_demographics hd_ship   ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.web_page wp                     ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.ship_mode sm_ws                  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN tpcds.promotion p_ws                   ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN tpcds.income_band ib_bill              ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN tpcds.income_band ib_ship              ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
JOIN tpcds.date_dim d_wp_creation           ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN tpcds.date_dim d_wp_access             ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN tpcds.date_dim d_promo_start           ON p_ss.p_start_date_sk = d_promo_start.d_date_sk
JOIN tpcds.date_dim d_promo_end             ON p_ss.p_end_date_sk = d_promo_end.d_date_sk

GROUP BY ROLLUP (s.s_store_name, p_ss.p_promo_name, sm_cr.sm_ship_mode_id, d_date.d_year)
ORDER BY overall_status DESC, s.s_store_name, d_date.d_year
LIMIT 100

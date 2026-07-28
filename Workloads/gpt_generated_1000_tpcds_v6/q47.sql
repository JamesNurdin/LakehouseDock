WITH base AS (
    SELECT
        w.w_warehouse_name,
        w.w_country,
        t_cr.t_shift,
        t_cr.t_meal_time,
        r_cat.r_reason_desc AS catalog_reason,
        site.web_name AS website_name,
        SUM(cr.cr_net_loss) AS total_catalog_loss,
        SUM(sr.sr_net_loss) AS total_store_loss,
        SUM(ws.ws_net_profit) AS total_web_profit,
        CASE WHEN SUM(cr.cr_net_loss + sr.sr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r_cat
        ON cr.cr_reason_sk = r_cat.r_reason_sk
    JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib_ref
        ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = t_cr.t_time_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN customer_demographics cd_sr
        ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN income_band ib_sr
        ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t_cr.t_time_sk
    JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN customer_demographics cd_ws_bill
        ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN household_demographics hd_ws_bill
        ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN income_band ib_ws_bill
        ON hd_ws_bill.hd_income_band_sk = ib_ws_bill.ib_income_band_sk
    WHERE t_cr.t_shift = 'first'
    GROUP BY
        w.w_warehouse_name,
        w.w_country,
        t_cr.t_shift,
        t_cr.t_meal_time,
        r_cat.r_reason_desc,
        site.web_name
)
SELECT *
FROM base
ORDER BY total_web_profit DESC

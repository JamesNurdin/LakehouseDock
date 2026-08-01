WITH ss_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        td_ss.t_hour AS hour,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        'STORE' AS channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN income_band ib_ss ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk
    GROUP BY i.i_item_id, i.i_category, td_ss.t_hour
),
ws_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        td_ws.t_hour AS hour,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        'WEB' AS channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN income_band ib_ws ON hd_ws.hd_income_band_sk = ib_ws.ib_income_band_sk
    GROUP BY i.i_item_id, i.i_category, td_ws.t_hour
),
combined_sales AS (
    SELECT * FROM ss_agg
    UNION ALL
    SELECT * FROM ws_agg
),
returns_agg AS (
    SELECT
        i.i_item_id,
        i.i_category,
        td_cr.t_hour AS hour,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        MAX(cc.cc_name) AS call_center_name,
        MAX(cp.cp_department) AS catalog_department
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd_cr ON cr.cr_refunded_hdemo_sk = hd_cr.hd_demo_sk
    JOIN income_band ib_cr ON hd_cr.hd_income_band_sk = ib_cr.ib_income_band_sk
    GROUP BY i.i_item_id, i.i_category, td_cr.t_hour
)
SELECT
    cs.i_item_id,
    cs.i_category,
    cs.hour,
    SUM(cs.total_net_paid) AS sum_total_net_paid,
    SUM(cs.total_discount) AS sum_total_discount,
    SUM(r.total_return_amount) AS sum_total_return_amount,
    SUM(r.total_return_quantity) AS sum_total_return_quantity,
    MAX(r.call_center_name) AS call_center_name,
    MAX(r.catalog_department) AS catalog_department
FROM combined_sales cs
LEFT JOIN returns_agg r
    ON cs.i_item_id = r.i_item_id
    AND cs.hour = r.hour
GROUP BY cs.i_item_id, cs.i_category, cs.hour
ORDER BY sum_total_net_paid DESC
LIMIT 100

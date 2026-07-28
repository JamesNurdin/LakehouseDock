WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_web_site_sk,
        ws_ship_mode_sk,
        ws_promo_sk,
        ws_sold_time_sk,
        ws_order_number,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_quantity) AS total_qty
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450815 AND 2450825
    GROUP BY ws_item_sk, ws_web_site_sk, ws_ship_mode_sk, ws_promo_sk, ws_sold_time_sk, ws_order_number
)
SELECT
    wsite.web_name,
    sm.sm_type,
    p.p_promo_name,
    td_ws.t_hour,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.total_net_paid) AS net_paid,
    SUM(ws.total_qty) AS total_quantity,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS catalog_return_amount,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS store_return_amount,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS web_return_amount
FROM ws_agg ws
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN time_dim td_ws
    ON ws.ws_sold_time_sk = td_ws.t_time_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN time_dim td_wr
    ON wr.wr_returned_time_sk = td_wr.t_time_sk
LEFT JOIN store_returns sr
    ON sr.sr_return_time_sk = td_ws.t_time_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = td_ws.t_time_sk
LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN customer_demographics cd_refund
    ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
LEFT JOIN household_demographics hd_refund
    ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
LEFT JOIN customer_demographics cd_return
    ON cr.cr_returning_cdemo_sk = cd_return.cd_demo_sk
LEFT JOIN household_demographics hd_return
    ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
LEFT JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
LEFT JOIN customer_demographics cd_wr_refund
    ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
LEFT JOIN household_demographics hd_wr_refund
    ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
LEFT JOIN customer_demographics cd_wr_return
    ON wr.wr_returning_cdemo_sk = cd_wr_return.cd_demo_sk
LEFT JOIN household_demographics hd_wr_return
    ON wr.wr_returning_hdemo_sk = hd_wr_return.hd_demo_sk
GROUP BY GROUPING SETS (
    (wsite.web_name, sm.sm_type, p.p_promo_name, td_ws.t_hour),
    (wsite.web_name, sm.sm_type, p.p_promo_name),
    (wsite.web_name, sm.sm_type),
    (wsite.web_name),
    ()
)
ORDER BY net_paid DESC
LIMIT 100

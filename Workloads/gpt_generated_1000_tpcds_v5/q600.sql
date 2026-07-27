SELECT
    s.s_state,
    p.p_channel_email,
    r_sr.r_reason_desc,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt
FROM store_returns sr
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sr.d_date_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN household_demographics hd_cr_refunded
    ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
JOIN household_demographics hd_cr_returning
    ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
JOIN promotion p
    ON p.p_start_date_sk = d_sr.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sr.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sr.d_date_sk
WHERE p.p_channel_email = 'N'
GROUP BY s.s_state, p.p_channel_email, r_sr.r_reason_desc
HAVING SUM(sr.sr_net_loss) > 10000
ORDER BY store_net_loss DESC
LIMIT 100

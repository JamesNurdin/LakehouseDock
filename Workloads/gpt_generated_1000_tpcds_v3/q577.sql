WITH base_agg AS (
    SELECT
        s.s_store_id,
        d.d_date,
        d.d_date_sk,
        SUM(sr.sr_return_amt) AS store_return_amt,
        SUM(cr.cr_return_amount) AS catalog_return_amt,
        SUM(wr.wr_return_amt) AS web_return_amt,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt
    FROM
        date_dim d
        JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN time_dim t2 ON wr.wr_returned_time_sk = t2.t_time_sk
        JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
        JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE
        p.p_channel_dmail = 'Y' AND
        p.p_channel_radio = 'N' AND
        hd.hd_income_band_sk IN (3, 12, 18) AND
        hd.hd_vehicle_count > 0 AND
        s.s_state = 'CA' AND
        cc.cc_gmt_offset BETWEEN -5.00 AND 5.00 AND
        d.d_year = 2001 AND
        t.t_hour BETWEEN 9 AND 17 AND
        cp.cp_type = 'A' AND
        sm.sm_type = 'AIR' AND
        w.w_state = 'TX'
    GROUP BY
        s.s_store_id,
        d.d_date,
        d.d_date_sk
)
SELECT
    b.s_store_id,
    COUNT(*) AS days_with_returns,
    AVG(b.store_net_loss + b.catalog_net_loss + b.web_net_loss) AS avg_total_net_loss,
    SUM(b.store_return_amt + b.catalog_return_amt + b.web_return_amt) AS sum_total_return_amt,
    (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_channel_dmail = 'Y') AS total_dmail_promos
FROM
    base_agg b
WHERE
    (b.store_return_amt + b.catalog_return_amt + b.web_return_amt) > 1000
GROUP BY
    b.s_store_id
HAVING
    COUNT(*) >= 5
ORDER BY
    avg_total_net_loss DESC
LIMIT 100

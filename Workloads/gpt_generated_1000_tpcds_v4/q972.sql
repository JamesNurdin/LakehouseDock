WITH sales_agg AS (
    SELECT
        hd.hd_demo_sk,
        p.p_channel_details,
        ss.ss_ticket_number,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit
    FROM household_demographics hd
    JOIN store_sales ss ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
)
SELECT
    cc.cc_name,
    sa.p_channel_details,
    sm1.sm_type,
    COUNT(DISTINCT sa.ss_ticket_number) AS sales_txn_cnt,
    SUM(sa.ss_net_paid_inc_tax) AS total_sales_net_inc_tax,
    SUM(cr.cr_net_loss) AS total_catalog_loss,
    SUM(wr.wr_net_loss) AS total_web_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt
FROM sales_agg sa
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_hdemo_sk = sa.hd_demo_sk
LEFT JOIN household_demographics hd_ret
    ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN ship_mode sm1
    ON cr.cr_ship_mode_sk = sm1.sm_ship_mode_sk
LEFT JOIN ship_mode sm2
    ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_hdemo_sk = sa.hd_demo_sk
LEFT JOIN household_demographics hd_wret
    ON wr.wr_returning_hdemo_sk = hd_wret.hd_demo_sk
WHERE cc.cc_country = 'United States'
GROUP BY cc.cc_name, sa.p_channel_details, sm1.sm_type
HAVING (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) > 10000
ORDER BY (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) DESC
LIMIT 100

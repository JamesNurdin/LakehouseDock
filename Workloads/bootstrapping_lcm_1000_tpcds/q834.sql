SELECT
    cc.cc_name,
    s.s_store_name,
    d_return.d_year,
    CASE
        WHEN d_return.d_month_seq BETWEEN 1 AND 6 THEN 'FirstHalf'
        ELSE 'SecondHalf'
    END AS half_year,
    MIN(DATE_DIFF('day', d_cc_open.d_date, d_cc_closed.d_date)) AS call_center_lifetime_days,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS total_returns,
    SUM(CASE WHEN cd_ref.cd_gender = 'M' THEN cr.cr_return_amount ELSE 0 END) AS male_refunded_return_amount,
    SUM(CASE WHEN cd_ret.cd_gender = 'F' THEN cr.cr_return_amount ELSE 0 END) AS female_returning_return_amount,
    ROUND(AVG(cc.cc_gmt_offset * s.s_gmt_offset), 2) AS avg_gmt_offset_product,
    MAX(d_return.d_date) AS latest_return_date
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_return.d_year,
    CASE
        WHEN d_return.d_month_seq BETWEEN 1 AND 6 THEN 'FirstHalf'
        ELSE 'SecondHalf'
    END
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100

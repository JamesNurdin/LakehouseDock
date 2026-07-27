WITH base_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_call_center_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_quantity,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_returning_hdemo_sk,
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_market_manager,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_ret.d_date_sk,
        t.t_hour,
        cd.cd_gender,
        hd.hd_buy_potential
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d_ret.d_year = 2001
      AND cc.cc_market_manager = 'Gary Colburn'
      AND hd.hd_buy_potential = '>10000'
      AND t.t_hour BETWEEN 9 AND 17
      AND cr.cr_return_amount > 100
)
SELECT
    bd.cc_call_center_id,
    bd.cc_name,
    bd.d_month_seq,
    bd.hd_buy_potential,
    SUM(bd.cr_return_amount) AS total_return_amount,
    AVG(bd.cr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MIN(bd.cr_return_quantity) AS min_qty,
    MAX(bd.cr_return_quantity) AS max_qty,
    cd_ret.cd_gender AS returning_gender,
    COALESCE(wp.wp_url, 'N/A') AS web_page_url
FROM base_data bd
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = bd.d_date_sk
JOIN customer_demographics cd_ret
    ON bd.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ret
    ON bd.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
GROUP BY
    bd.cc_call_center_id,
    bd.cc_name,
    bd.d_month_seq,
    bd.hd_buy_potential,
    cd_ret.cd_gender,
    COALESCE(wp.wp_url, 'N/A')
HAVING SUM(bd.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100

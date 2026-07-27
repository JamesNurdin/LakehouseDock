WITH joined AS (
    SELECT
        cr.cr_return_amount,
        cc.cc_call_center_id,
        cc.cc_state,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_state = 'TX'
      AND cc.cc_gmt_offset BETWEEN -6.00 AND -5.00
      AND cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate >= 3000
      AND hd.hd_income_band_sk IN (10, 11, 14)
      AND hd.hd_buy_potential = '1001-5000'
),
agg AS (
    SELECT
        cc_call_center_id,
        cc_state,
        cd_gender,
        hd_income_band_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr_return_amount) AS avg_return_amount
    FROM joined
    GROUP BY cc_call_center_id, cc_state, cd_gender, hd_income_band_sk
)
SELECT
    cc_call_center_id,
    cc_state,
    cd_gender,
    hd_income_band_sk,
    total_return_amount,
    return_cnt,
    avg_return_amount,
    RANK() OVER (PARTITION BY cc_state ORDER BY total_return_amount DESC) AS state_rank,
    SUM(total_return_amount) OVER (PARTITION BY cd_gender) AS gender_total_return
FROM agg
WHERE return_cnt > 10
ORDER BY total_return_amount DESC
LIMIT 100

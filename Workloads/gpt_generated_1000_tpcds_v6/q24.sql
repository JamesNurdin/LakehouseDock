WITH sr_cd_hd AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        cd.cd_demo_sk,
        cd.cd_purchase_estimate,
        cd.cd_dep_employed_count,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_income_band_sk
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_store_sk IN (751, 896)
      AND hd.hd_buy_potential = '1001-5000'
      AND cd.cd_purchase_estimate >= 5000
)
SELECT
    cc.cc_call_center_id,
    cc.cc_state,
    COUNT(DISTINCT sr_cd_hd.sr_ticket_number) AS num_returns,
    SUM(sr_cd_hd.sr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MAX(cc.cc_employees) AS max_employees,
    (SELECT MAX(cc2.cc_employees) FROM call_center cc2 WHERE cc2.cc_state = 'CA') AS state_max_employees
FROM sr_cd_hd
JOIN catalog_returns cr
    ON cr.cr_refunded_cdemo_sk = sr_cd_hd.cd_demo_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_state = 'CA'
  AND cc.cc_employees = (
        SELECT MAX(cc3.cc_employees)
        FROM call_center cc3
        WHERE cc3.cc_state = 'CA'
      )
GROUP BY cc.cc_call_center_id, cc.cc_state
ORDER BY total_net_loss DESC
LIMIT 100

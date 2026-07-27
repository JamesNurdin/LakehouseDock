WITH cr_agg AS (
    SELECT
        cr_call_center_sk,
        cr_reason_sk,
        cr_ship_mode_sk,
        SUM(cr_net_loss) AS sum_net_loss,
        AVG(cr_return_amount) AS avg_return_amount,
        COUNT(*) AS cnt_returns,
        MIN(cr_return_amount) AS min_return_amount,
        MAX(cr_return_amount) AS max_return_amount
    FROM catalog_returns
    WHERE cr_net_loss > 200
      AND cr_return_amount > 50
      AND cr_return_quantity BETWEEN 1 AND 5
      AND cr_reversed_charge < 300
      AND cr_fee BETWEEN 10 AND 100
      AND cr_returned_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY cr_call_center_sk, cr_reason_sk, cr_ship_mode_sk
)
SELECT
    cc.cc_company,
    cc.cc_state,
    cc.cc_county,
    r.r_reason_desc,
    sm.sm_type,
    cr_agg.sum_net_loss,
    cr_agg.avg_return_amount,
    cr_agg.cnt_returns,
    cr_agg.min_return_amount,
    cr_agg.max_return_amount,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY cr_agg.sum_net_loss DESC) AS state_net_loss_rank
FROM cr_agg
JOIN call_center cc
    ON cr_agg.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r
    ON cr_agg.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
    ON cr_agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cc.cc_county IN ('Levy County', 'Maverick County')
  AND cc.cc_tax_percentage > 0.05
  AND cc.cc_company = 5
  AND cc.cc_state = 'TX'
  AND r.r_reason_id = 'AAAAAAAAIAAAAAAA'
  AND sm.sm_type = 'AIR'
  AND sm.sm_carrier = 'UPS'
ORDER BY cr_agg.sum_net_loss DESC
LIMIT 100

WITH agg AS (
    SELECT cr_call_center_sk,
           SUM(cr_return_amount) AS total_return_amount,
           SUM(cr_return_quantity) AS total_return_quantity
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_call_center_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_state,
    cd.cd_credit_rating,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    w.w_warehouse_name,
    agg.total_return_amount,
    agg.total_return_quantity,
    CASE WHEN agg.total_return_amount > (
            SELECT AVG(cr_return_amount)
            FROM catalog_returns
         ) THEN 'High'
         ELSE 'Low'
    END AS amount_category,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY agg.total_return_amount DESC) AS state_rank
FROM call_center cc
JOIN agg ON agg.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = cr.cr_returning_cdemo_sk
JOIN household_demographics hd ON hd.hd_demo_sk = cr.cr_returning_hdemo_sk
JOIN warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
WHERE cc.cc_state = 'CA'
  AND cc.cc_company > 2
  AND cd.cd_credit_rating = 'Good'
  AND cd.cd_marital_status = 'M'
  AND hd.hd_buy_potential IN ('501-1000', '1001-5000')
  AND hd.hd_vehicle_count >= 1
  AND w.w_state = 'CA'
  AND cr.cr_return_amount > 100
ORDER BY agg.total_return_amount DESC
LIMIT 100

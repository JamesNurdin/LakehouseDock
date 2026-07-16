SELECT
    i.i_category,
    hd_ret.hd_income_band_sk,
    hd_ref.hd_vehicle_count AS refunded_vehicle_count,
    (cr.cr_returned_date_sk / 100) AS year_month,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_store_credit) AS total_store_credit,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_net_loss) AS total_net_loss
FROM catalog_returns cr
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN household_demographics hd_ret
  ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
WHERE cr.cr_store_credit > 50
  AND i.i_current_price > 20
  AND hd_ret.hd_buy_potential = 'High'
  AND hd_ref.hd_vehicle_count >= 1
  AND cr.cr_returned_date_sk BETWEEN 20000101 AND 20001231
GROUP BY i.i_category,
         hd_ret.hd_income_band_sk,
         hd_ref.hd_vehicle_count,
         (cr.cr_returned_date_sk / 100)
HAVING COUNT(*) >= 5
ORDER BY total_return_amount DESC
LIMIT 50

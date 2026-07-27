WITH filtered_returns AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_return_quantity,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returning_hdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100.00
      AND cr.cr_refunded_cash > 0.00
      AND cr.cr_reversed_charge < 500.00
      AND cr.cr_return_quantity >= 1
      AND EXISTS (
          SELECT 1
          FROM household_demographics hd
          WHERE hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
            AND hd.hd_dep_count >= 1
            AND hd.hd_vehicle_count >= 2
      )
)
SELECT
    cc.cc_name,
    cc.cc_state,
    hd.hd_buy_potential,
    fr.cr_return_amount,
    fr.cr_refunded_cash,
    fr.cr_reversed_charge,
    SUM(fr.cr_return_amount) OVER (
        PARTITION BY cc.cc_state
        ORDER BY fr.cr_returned_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_return_amount_state,
    RANK() OVER (
        PARTITION BY cc.cc_state
        ORDER BY fr.cr_return_amount DESC
    ) AS amount_rank_state,
    CASE
        WHEN fr.cr_return_amount > 500 THEN 'High'
        WHEN fr.cr_return_amount > 200 THEN 'Medium'
        ELSE 'Low'
    END AS amount_category
FROM filtered_returns fr
JOIN call_center cc
    ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN household_demographics hd
    ON fr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE cc.cc_country = 'United States'
  AND cc.cc_gmt_offset BETWEEN -5.00 AND 0.00
  AND cc.cc_tax_percentage < 5.00
  AND cc.cc_employees > 50
ORDER BY cc.cc_state, amount_rank_state
LIMIT 100

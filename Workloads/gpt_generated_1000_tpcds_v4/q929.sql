WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_item_sk,
        cr_refunded_customer_sk,
        cr_refunded_hdemo_sk,
        cr_refunded_addr_sk,
        cr_returning_customer_sk,
        cr_call_center_sk,
        cr_warehouse_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_return_tax,
        cr_return_amt_inc_tax,
        cr_fee,
        cr_return_ship_cost,
        cr_refunded_cash,
        cr_reversed_charge,
        cr_store_credit,
        cr_net_loss
    FROM catalog_returns
    WHERE cr_refunded_hdemo_sk IN (6055, 962)
      AND cr_refunded_addr_sk = 1224989
      AND cr_return_quantity > 0
      AND cr_return_amount > 0
      AND cr_return_tax >= 0
      AND cr_return_amount < 10000
)
SELECT
    cc.cc_name,
    cc.cc_state,
    w.w_city,
    w.w_country,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_count,
    MIN(fr.cr_return_tax) AS min_return_tax,
    MAX(fr.cr_return_tax) AS max_return_tax
FROM filtered_returns fr
JOIN call_center cc
  ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON fr.cr_warehouse_sk = w.w_warehouse_sk
WHERE cc.cc_country = 'United States'
  AND cc.cc_hours = '8AM-4PM'
  AND cc.cc_street_name = 'Main'
  AND cc.cc_street_number = '415'
  AND w.w_suite_number = 'Suite 160'
  AND w.w_street_type = 'Avenue'
  AND cc.cc_rec_start_date <= DATE '2001-01-01'
  AND (cc.cc_rec_end_date IS NULL OR cc.cc_rec_end_date >= DATE '2001-01-01')
GROUP BY
    cc.cc_name,
    cc.cc_state,
    w.w_city,
    w.w_country
ORDER BY total_return_amount DESC
LIMIT 100

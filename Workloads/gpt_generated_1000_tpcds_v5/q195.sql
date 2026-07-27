/*
  Goal: Summarize catalog return performance by call center, item category and hour of day, 
  focusing on high‑value returns, specific brands, and California call centers within a two‑year window.
*/
WITH filtered_returns AS (
    SELECT
        cr_returned_time_sk,
        cr_item_sk,
        cr_refunded_customer_sk,
        cr_refunded_cdemo_sk,
        cr_refunded_hdemo_sk,
        cr_returning_customer_sk,
        cr_returning_cdemo_sk,
        cr_returning_hdemo_sk,
        cr_call_center_sk,
        cr_order_number,
        cr_return_amount,
        cr_fee,
        cr_store_credit,
        cr_return_quantity,
        cr_net_loss
    FROM catalog_returns
    WHERE cr_return_amount > 100.00
      AND cr_store_credit < 200.00
      AND cr_fee >= 20.00
      AND cr_return_quantity >= 1
)
SELECT
    cc.cc_name AS call_center_name,
    i.i_category AS item_category,
    td.t_hour AS return_hour,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_fee) AS avg_fee,
    COUNT(DISTINCT fr.cr_order_number) AS distinct_orders,
    MAX(fr.cr_net_loss) AS max_net_loss
FROM filtered_returns fr
JOIN call_center cc
    ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN time_dim td
    ON fr.cr_returned_time_sk = td.t_time_sk
JOIN item i
    ON fr.cr_item_sk = i.i_item_sk
JOIN customer c_refunded
    ON fr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_demographics cd_refunded
    ON fr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded
    ON fr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer c_returning
    ON fr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer_demographics cd_returning
    ON fr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_returning
    ON fr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
WHERE cc.cc_state = 'CA'
  AND cc.cc_gmt_offset BETWEEN -5.00 AND -4.00
  AND cc.cc_rec_start_date >= DATE '2001-01-01'
  AND cc.cc_rec_end_date   <= DATE '2002-12-31'
  AND i.i_brand = 'BrandX'
  AND td.t_hour BETWEEN 9 AND 17
  AND hd_refunded.hd_vehicle_count >= 2
GROUP BY
    cc.cc_name,
    i.i_category,
    td.t_hour
ORDER BY
    total_return_amount DESC
LIMIT 100

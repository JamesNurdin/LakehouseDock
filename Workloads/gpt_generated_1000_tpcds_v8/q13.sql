WITH store_agg AS (
    SELECT
        sr_hdemo_sk,
        COUNT(*) AS store_return_cnt,
        SUM(sr_return_amt) AS store_return_total,
        AVG(sr_return_quantity) AS avg_store_qty,
        MAX(sr_reversed_charge) AS max_reversed_charge
    FROM store_returns
    WHERE sr_return_quantity >= 5
      AND sr_reversed_charge > 100
      AND sr_return_amt BETWEEN 50 AND 500
    GROUP BY sr_hdemo_sk
)
SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_fee) AS avg_return_fee,
    MIN(cr.cr_return_quantity) AS min_return_qty,
    MAX(cr.cr_return_quantity) AS max_return_qty,
    store_agg.store_return_cnt,
    store_agg.store_return_total
FROM catalog_returns cr
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_agg
  ON hd.hd_demo_sk = store_agg.sr_hdemo_sk
WHERE cr.cr_returned_date_sk BETWEEN 2450900 AND 2451100
  AND cr.cr_call_center_sk IN (1, 10, 22)
  AND cr.cr_return_amount > 20
  AND cr.cr_fee < 5
  AND hd.hd_vehicle_count >= 0
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_hdemo_sk = hd.hd_demo_sk
          AND sr.sr_return_quantity > 10
          AND sr.sr_return_amt_inc_tax > 100
   )
GROUP BY
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    store_agg.store_return_cnt,
    store_agg.store_return_total
ORDER BY total_return_amount DESC
LIMIT 100

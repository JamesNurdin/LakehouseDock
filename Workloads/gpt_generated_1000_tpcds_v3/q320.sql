WITH sr_agg AS (
    SELECT
        sr_hdemo_sk,
        COUNT(*) AS sr_return_cnt,
        SUM(sr_return_amt) AS sr_total_return_amt,
        SUM(sr_store_credit) AS sr_total_store_credit
    FROM store_returns
    WHERE sr_store_credit > 100
      AND sr_refunded_cash < 800
      AND sr_reversed_charge >= 5
      AND sr_return_quantity > 0
      AND sr_return_amt > 0
      AND sr_return_tax >= 0
    GROUP BY sr_hdemo_sk
),
cr_agg AS (
    SELECT
        cr_warehouse_sk,
        cr_refunded_hdemo_sk,
        COUNT(*) AS cr_return_cnt,
        SUM(cr_return_amount) AS cr_total_return_amt,
        SUM(cr_net_loss) AS cr_total_net_loss
    FROM catalog_returns
    WHERE cr_return_quantity > 0
      AND cr_return_amount > 0
      AND cr_return_tax >= 0
      AND cr_fee >= 0
      AND cr_return_ship_cost >= 0
      AND cr_refunded_cash >= 0
    GROUP BY cr_warehouse_sk, cr_refunded_hdemo_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    hd_sr.hd_buy_potential,
    SUM(sa.sr_total_return_amt) AS sum_store_return_amt,
    SUM(ca.cr_total_return_amt) AS sum_catalog_return_amt,
    SUM(sa.sr_total_store_credit) AS sum_store_credit,
    SUM(ca.cr_total_net_loss) AS sum_catalog_net_loss,
    COUNT(DISTINCT sa.sr_hdemo_sk) AS distinct_household_demo_cnt
FROM sr_agg sa
JOIN household_demographics hd_sr
    ON sa.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN cr_agg ca
    ON ca.cr_refunded_hdemo_sk = hd_sr.hd_demo_sk
JOIN warehouse w
    ON ca.cr_warehouse_sk = w.w_warehouse_sk
WHERE hd_sr.hd_vehicle_count >= 1
  AND hd_sr.hd_buy_potential = '5001-10000'
  AND w.w_warehouse_sq_ft BETWEEN 500000 AND 1000000
  AND w.w_zip IN ('19231', '63451')
  AND w.w_country = 'United States'
  AND w.w_gmt_offset >= -5
GROUP BY w.w_warehouse_id, w.w_city, w.w_state, hd_sr.hd_buy_potential
HAVING SUM(sa.sr_total_return_amt) > 1000
ORDER BY sum_catalog_return_amt DESC
LIMIT 100

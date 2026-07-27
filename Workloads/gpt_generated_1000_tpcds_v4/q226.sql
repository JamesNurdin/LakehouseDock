WITH store_agg AS (
    SELECT
        sr_hdemo_sk,
        COUNT(*) AS store_return_cnt,
        SUM(sr_return_amt) AS store_return_total,
        AVG(sr_return_tax) AS avg_store_tax
    FROM store_returns
    WHERE sr_return_tax > 20.00
      AND sr_customer_sk IN (1262835, 4104451, 344047)
      AND sr_returned_date_sk BETWEEN 2452000 AND 2453000
    GROUP BY sr_hdemo_sk
)
SELECT
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    sa.store_return_cnt,
    sa.store_return_total,
    sa.avg_store_tax,
    (
        SELECT AVG(cr2.cr_net_loss)
        FROM catalog_returns cr2
        WHERE cr2.cr_reversed_charge > 100
    ) AS avg_catalog_net_loss_overall
FROM catalog_returns cr
JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN store_agg sa
    ON sa.sr_hdemo_sk = hd.hd_demo_sk
WHERE cr.cr_reversed_charge > 100
  AND cr.cr_return_quantity BETWEEN 1 AND 5
  AND cr.cr_return_amount > 10.00
  AND cr.cr_fee < 20.00
  AND cr.cr_return_ship_cost IS NOT NULL
GROUP BY
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    sa.store_return_cnt,
    sa.store_return_total,
    sa.avg_store_tax
ORDER BY total_catalog_return_amount DESC
LIMIT 100

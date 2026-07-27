WITH warehouse_income_agg AS (
    SELECT
        cr.cr_warehouse_sk,
        hd.hd_income_band_sk,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        CASE
            WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH'
            WHEN SUM(cr.cr_net_loss) > 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_category
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_warehouse_sk IN (4, 6, 15, 18, 19)
      AND cr.cr_return_quantity >= 1
      AND cr.cr_return_amount > 10
      AND hd.hd_income_band_sk BETWEEN 8 AND 20
      AND hd.hd_vehicle_count >= 0
      AND hd.hd_dep_count <= 8
    GROUP BY cr.cr_warehouse_sk, hd.hd_income_band_sk
)
SELECT
    wia.cr_warehouse_sk,
    wia.hd_income_band_sk,
    wia.total_net_loss,
    wia.return_cnt,
    wia.avg_return_amount,
    wia.loss_category,
    (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS overall_avg_net_loss,
    wia.total_net_loss / NULLIF((SELECT SUM(cr3.cr_net_loss) FROM catalog_returns cr3), 0) AS loss_share
FROM warehouse_income_agg wia
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    JOIN customer_demographics cd
        ON cr2.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr2.cr_warehouse_sk = wia.cr_warehouse_sk
      AND cd.cd_gender = 'M'
      AND cd.cd_credit_rating = 'good'
)
  AND wia.total_net_loss > 0
ORDER BY wia.total_net_loss DESC
LIMIT 100

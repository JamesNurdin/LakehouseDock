WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_net_loss,
        cr_catalog_page_sk,
        cr_ship_mode_sk,
        cr_refunded_cdemo_sk,
        cr_refunded_hdemo_sk
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450000 AND 2451000
      AND cr_return_quantity > 0
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    sm.sm_carrier,
    SUM(fr.cr_net_loss) AS total_net_loss,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    COUNT(*) AS return_cnt,
    MIN(fr.cr_return_quantity) AS min_qty,
    MAX(fr.cr_return_quantity) AS max_qty,
    (SELECT AVG(cr_net_loss) FROM catalog_returns) AS overall_avg_net_loss
FROM filtered_returns fr
JOIN catalog_page cp
    ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd_ref
    ON fr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN household_demographics hd
    ON fr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE cp.cp_type = 'monthly'
  AND cp.cp_catalog_page_id = 'AAAAAAAAPAAAAAAA'
  AND sm.sm_contract = 'HVDFCcQ'
  AND hd.hd_vehicle_count >= 2
  AND cd_ref.cd_gender = 'F'
GROUP BY cp.cp_catalog_page_id, cp.cp_type, sm.sm_carrier
ORDER BY total_net_loss DESC
LIMIT 100

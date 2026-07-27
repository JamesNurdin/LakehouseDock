WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_refunded_cdemo_sk,
        cc.cc_name,
        cc.cc_company_name,
        i.i_brand,
        i.i_current_price,
        sm.sm_carrier,
        sm.sm_code
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE i.i_current_price > 100.00
      AND sm.sm_code = 'AIR'
      AND cc.cc_company_name = 'anti'
      AND cr.cr_return_amount > 50.00
)
SELECT
    fr.cc_name,
    fr.sm_carrier,
    fr.i_brand,
    SUM(fr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(fr.i_current_price) AS avg_price,
    MIN(fr.cr_return_quantity) AS min_qty,
    MAX(fr.cr_return_quantity) AS max_qty
FROM filtered_returns fr
WHERE EXISTS (
    SELECT 1
    FROM customer_demographics cd
    WHERE cd.cd_demo_sk = fr.cr_refunded_cdemo_sk
      AND cd.cd_purchase_estimate > 5000
)
GROUP BY fr.cc_name, fr.sm_carrier, fr.i_brand
ORDER BY total_return_amount DESC
LIMIT 100

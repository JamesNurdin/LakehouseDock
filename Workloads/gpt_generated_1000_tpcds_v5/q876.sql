WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_return_amount,
        cr_return_quantity,
        cr_call_center_sk,
        cr_item_sk,
        cr_catalog_page_sk,
        cr_reason_sk,
        cr_fee,
        cr_net_loss
    FROM catalog_returns AS cr
    WHERE cr_return_amount > 100
      AND cr_return_quantity >= 1
      AND cr_returned_date_sk BETWEEN 2450000 AND 2452000
)
SELECT
    cc.cc_state,
    i.i_category,
    reason.r_reason_desc,
    CASE
        WHEN fr.cr_return_amount > 500 THEN 'High'
        ELSE 'Low'
    END AS return_level,
    COUNT(*) AS returns_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    MIN(fr.cr_return_amount) AS min_return_amount,
    MAX(fr.cr_return_amount) AS max_return_amount,
    (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) AS overall_avg_return_amount
FROM filtered_returns AS fr
JOIN item i ON fr.cr_item_sk = i.i_item_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
JOIN call_center cc ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason ON fr.cr_reason_sk = reason.r_reason_sk
WHERE i.i_brand = 'BrandX'
  AND cc.cc_state = 'CA'
  AND cp.cp_catalog_number IN (1, 3, 11)
  AND reason.r_reason_desc LIKE 'Lost my job%'
  AND inv.inv_quantity_on_hand < 50
GROUP BY
    cc.cc_state,
    i.i_category,
    reason.r_reason_desc,
    CASE
        WHEN fr.cr_return_amount > 500 THEN 'High'
        ELSE 'Low'
    END
ORDER BY total_return_amount DESC
LIMIT 100

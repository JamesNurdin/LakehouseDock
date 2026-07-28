WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_net_loss,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_item_sk,
        cr.cr_reason_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
      AND cr.cr_return_quantity >= 1
      AND cr.cr_returned_date_sk BETWEEN 2450900 AND 2451000
      AND cr.cr_fee < 10
      AND cr.cr_return_ship_cost IS NOT NULL
      AND cr.cr_net_loss > -1000
)
SELECT
    cc.cc_name AS call_center_name,
    cc.cc_state,
    cp.cp_type,
    i.i_item_id,
    i.i_current_price,
    r.r_reason_desc,
    SUM(fr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    CASE WHEN SUM(fr.cr_return_amount) > 5000 THEN 'High' ELSE 'Medium' END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY SUM(fr.cr_return_amount) DESC) AS rn
FROM filtered_returns fr
JOIN call_center cc
  ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
  ON fr.cr_item_sk = i.i_item_sk
JOIN reason r
  ON fr.cr_reason_sk = r.r_reason_sk
LEFT JOIN inventory inv
  ON i.i_item_sk = inv.inv_item_sk
WHERE cc.cc_state = 'CA'
  AND i.i_current_price BETWEEN 10 AND 1000
  AND cp.cp_type IN ('monthly', 'quarterly')
  AND r.r_reason_id LIKE 'AAAAAAA%'
  AND (inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand > 0)
  AND cc.cc_gmt_offset BETWEEN -5 AND 5
  AND EXISTS (
        SELECT 1 FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
          AND inv2.inv_quantity_on_hand > 10
    )
GROUP BY
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_state,
    cp.cp_type,
    i.i_item_id,
    i.i_current_price,
    r.r_reason_desc
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC, rn
LIMIT 100

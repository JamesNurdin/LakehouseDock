WITH returns_by_category AS (
    SELECT
        cc.cc_name AS call_center_name,
        'Category_5_7' AS filter_type,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_category_id IN (5, 7)
      AND cc.cc_gmt_offset = -6.00
      AND inv.inv_quantity_on_hand > 0
    GROUP BY cc.cc_name
),
returns_by_formulation AS (
    SELECT
        cc.cc_name AS call_center_name,
        'Formulation_Steel' AS filter_type,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_formulation LIKE '%steel%'
      AND cc.cc_hours LIKE '8AM-4PM%'
      AND inv.inv_quantity_on_hand > 0
    GROUP BY cc.cc_name
)
SELECT call_center_name, filter_type, total_return_amount
FROM returns_by_category
UNION ALL
SELECT call_center_name, filter_type, total_return_amount
FROM returns_by_formulation
ORDER BY call_center_name, total_return_amount DESC
LIMIT 100

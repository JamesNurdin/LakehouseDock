WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)   -- sample ~10% of rows
),
sub1 AS (
    SELECT
        cr.cr_order_number,
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        i.i_item_id,
        r.r_reason_id,
        cr.cr_return_amount,
        SUM(cr.cr_return_amount) OVER (PARTITION BY cc.cc_call_center_id) AS total_return_by_center,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY cr.cr_return_amount DESC) AS rn_center,
        CASE WHEN cr.cr_return_amount > 200 THEN 'high' ELSE 'low' END AS amount_category
    FROM sampled_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_county LIKE '%County%'
      AND r.r_reason_id = 'AAAAAAAABBAAAAAA'
      AND i.i_category_id = 4
      AND i.i_size = 'small'
      AND cr.cr_return_amount > 100
),
sub2 AS (
    SELECT
        cr.cr_order_number,
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        i.i_item_id,
        r.r_reason_id,
        cr.cr_return_amount,
        SUM(cr.cr_return_amount) OVER (PARTITION BY i.i_category_id) AS total_return_by_category,
        DENSE_RANK() OVER (ORDER BY cr.cr_return_amount DESC) AS dr_amount_rank,
        CASE WHEN cr.cr_return_quantity > 10 THEN 'bulk' ELSE 'single' END AS qty_type
    FROM sampled_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_city = 'Center'
      AND cp.cp_type = 'online'
      AND i.i_current_price < 500
      AND cr.cr_return_quantity BETWEEN 1 AND 10
      AND cr.cr_return_amount BETWEEN 50 AND 500
),
intersect_keys AS (
    SELECT cr_order_number FROM sub1
    INTERSECT
    SELECT cr_order_number FROM sub2
)
SELECT
    s1.cr_order_number,
    s1.cc_call_center_id,
    s1.cp_catalog_page_id,
    s1.i_item_id,
    s1.r_reason_id,
    s1.amount_category,
    s1.total_return_by_center,
    s2.total_return_by_category,
    s2.dr_amount_rank,
    s2.qty_type
FROM sub1 s1
JOIN sub2 s2 ON s1.cr_order_number = s2.cr_order_number
JOIN intersect_keys ik ON s1.cr_order_number = ik.cr_order_number
WHERE s1.rn_center = 1
ORDER BY s1.total_return_by_center DESC, s2.dr_amount_rank
LIMIT 100

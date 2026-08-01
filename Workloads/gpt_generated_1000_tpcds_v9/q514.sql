WITH
    agg_returns AS (
        SELECT
            cr_item_sk,
            cr_call_center_sk,
            cr_catalog_page_sk,
            cr_ship_mode_sk,
            SUM(cr_return_quantity) AS total_return_qty,
            SUM(cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt,
            AVG(cr_return_tax) AS avg_return_tax
        FROM catalog_returns
        WHERE cr_return_amount > 0
        GROUP BY cr_item_sk, cr_call_center_sk, cr_catalog_page_sk, cr_ship_mode_sk
    ),
    filtered_item AS (
        SELECT
            i_item_sk,
            i_item_id,
            i_brand_id,
            i_units,
            i_current_price,
            i_color
        FROM item
        WHERE i_brand_id = 2002002
          AND i_units = 'Box'
    ),
    intersect_item AS (
        SELECT i_item_sk FROM filtered_item
        INTERSECT
        SELECT cr_item_sk FROM agg_returns WHERE total_return_amount > 1000
    )
SELECT
    cc.cc_name,
    cp.cp_catalog_page_number,
    sm.sm_type,
    COUNT(DISTINCT i.i_item_id) AS distinct_item_cnt,
    SUM(ar.total_return_qty) AS sum_return_qty,
    SUM(ar.total_return_amount) AS sum_return_amount,
    AVG(ar.total_return_amount) AS avg_return_amount,
    MAX(ar.total_return_amount) AS max_return_amount,
    CASE
        WHEN SUM(ar.total_return_amount) > 10000 THEN 'Very High'
        WHEN SUM(ar.total_return_amount) > 5000 THEN 'High'
        ELSE 'Medium'
    END AS return_category
FROM agg_returns ar
JOIN intersect_item ii ON ar.cr_item_sk = ii.i_item_sk
JOIN item i ON ar.cr_item_sk = i.i_item_sk
JOIN call_center cc ON ar.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON ar.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON ar.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cc.cc_sq_ft > 500000000
  AND cc.cc_open_date_sk BETWEEN 2451040 AND 2451080
  AND cp.cp_catalog_page_number = 12
  AND sm.sm_type = 'AIR'
  AND i.i_brand_id = 2002002
  AND i.i_units = 'Box'
GROUP BY cc.cc_name, cp.cp_catalog_page_number, sm.sm_type
HAVING SUM(ar.total_return_amount) > 1000
ORDER BY sum_return_amount DESC
LIMIT 100

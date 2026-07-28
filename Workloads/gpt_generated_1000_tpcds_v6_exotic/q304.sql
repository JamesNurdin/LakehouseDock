WITH unified_returns AS (
    SELECT
        'store' AS return_source,
        i.i_category AS category,
        i.i_item_id AS item_id,
        SUM(sr.sr_return_amt) AS return_amount
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_manager = 'Scott Smith'
    GROUP BY i.i_category, i.i_item_id
    UNION ALL
    SELECT
        'catalog' AS return_source,
        i.i_category AS category,
        i.i_item_id AS item_id,
        SUM(cr.cr_return_amount) AS return_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city = 'San Francisco'
    GROUP BY i.i_category, i.i_item_id
)
SELECT
    return_source,
    category,
    item_id,
    SUM(return_amount) AS total_return_amount
FROM unified_returns
GROUP BY GROUPING SETS (
    (return_source, category, item_id),
    (return_source, category),
    (return_source),
    ()
)
ORDER BY
    return_source,
    category,
    item_id
LIMIT 100

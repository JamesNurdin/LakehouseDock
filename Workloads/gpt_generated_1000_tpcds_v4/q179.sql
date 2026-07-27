WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_category,
        i_units,
        i_current_price
    FROM item
    WHERE i_category IN ('Electronics', 'Sports')
)
,
catalog_agg AS (
    SELECT
        fi.i_item_id AS item_id,
        'Catalog' AS return_source,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS amount_level
    FROM catalog_returns cr
    JOIN filtered_items fi ON cr.cr_item_sk = fi.i_item_sk
    WHERE cr.cr_return_quantity > 0
    GROUP BY fi.i_item_id
)
,
web_agg AS (
    SELECT
        fi.i_item_id AS item_id,
        'Web' AS return_source,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS amount_level
    FROM web_returns wr
    JOIN filtered_items fi ON wr.wr_item_sk = fi.i_item_sk
    WHERE wr.wr_return_quantity > 0
    GROUP BY fi.i_item_id
)
SELECT DISTINCT
    item_id,
    return_source,
    total_return_amount,
    return_cnt,
    amount_level
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
) combined
ORDER BY total_return_amount DESC
LIMIT 100

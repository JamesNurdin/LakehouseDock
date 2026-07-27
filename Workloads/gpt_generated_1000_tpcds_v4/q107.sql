WITH filtered_items AS (
    SELECT i_item_sk, i_brand_id, i_current_price
    FROM item
    WHERE i_current_price > 100
)
SELECT
    source,
    t_hour,
    SUM(return_amount) AS total_return_amount
FROM (
    SELECT
        'store' AS source,
        t.t_hour,
        sr.sr_return_amt AS return_amount
    FROM store_returns sr
    JOIN filtered_items fi ON sr.sr_item_sk = fi.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
    UNION ALL
    SELECT
        'catalog' AS source,
        t.t_hour,
        cr.cr_return_amount AS return_amount
    FROM catalog_returns cr
    JOIN filtered_items fi ON cr.cr_item_sk = fi.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'CA'
) AS combined
GROUP BY source, t_hour
ORDER BY total_return_amount DESC
LIMIT 100

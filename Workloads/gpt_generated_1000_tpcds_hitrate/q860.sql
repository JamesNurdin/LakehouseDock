WITH catalog_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        cr.cr_returned_date_sk,
        i.i_item_id,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        (SELECT max(i2.i_current_price) FROM item i2) AS max_item_price,
        array[cr.cr_return_amount, cr.cr_return_tax, cr.cr_return_amt_inc_tax] AS return_metrics
    FROM catalog_returns cr
    RIGHT OUTER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE cp.cp_department = 'Electronics'
)
SELECT
    ca.cp_catalog_page_id AS page_id,
    ca.cp_catalog_page_number AS page_number,
    ca.cr_returned_date_sk AS return_date_sk,
    ca.i_item_id AS item_id,
    CASE u.metric_ord
        WHEN 1 THEN 'return_amount'
        WHEN 2 THEN 'return_tax'
        WHEN 3 THEN 'return_amount_inc_tax'
    END AS metric_name,
    u.metric_value AS metric_value,
    ca.max_item_price AS price_reference
FROM catalog_agg ca
CROSS JOIN UNNEST(ca.return_metrics) WITH ORDINALITY AS u(metric_value, metric_ord)
WHERE u.metric_value > 0

UNION ALL

SELECT
    'WEB' AS page_id,
    NULL AS page_number,
    wr.wr_returned_date_sk AS return_date_sk,
    i2.i_item_id AS item_id,
    CASE u.metric_ord
        WHEN 1 THEN 'return_amount'
        WHEN 2 THEN 'return_tax'
        WHEN 3 THEN 'return_amount_inc_tax'
    END AS metric_name,
    u.metric_value AS metric_value,
    (SELECT min(i3.i_current_price) FROM item i3) AS price_reference
FROM web_returns wr
JOIN item i2
    ON wr.wr_item_sk = i2.i_item_sk
CROSS JOIN UNNEST(array[wr.wr_return_amt, wr.wr_return_tax, wr.wr_return_amt_inc_tax]) WITH ORDINALITY AS u(metric_value, metric_ord)
WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2459999
  AND u.metric_value > 0

ORDER BY page_id, return_date_sk DESC
LIMIT 100

WITH high_value_returns AS (
    SELECT 
        i.i_manufact_id AS manufacturer_id,
        'return_amount_inc_tax' AS metric_name,
        SUM(cr.cr_return_amt_inc_tax) AS metric_value
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amt_inc_tax > 2000
      AND i.i_current_price < 5
    GROUP BY i.i_manufact_id
),
high_store_credit AS (
    SELECT 
        i.i_manufact_id AS manufacturer_id,
        'store_credit' AS metric_name,
        SUM(cr.cr_store_credit) AS metric_value
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_store_credit > 100
      AND i.i_formulation LIKE '%goldenrod%'
    GROUP BY i.i_manufact_id
),
combined AS (
    SELECT manufacturer_id, metric_name, metric_value
    FROM high_value_returns
    UNION ALL
    SELECT manufacturer_id, metric_name, metric_value
    FROM high_store_credit
)
SELECT 
    manufacturer_id,
    metric_name,
    metric_value,
    row_number() OVER (PARTITION BY metric_name ORDER BY metric_value DESC) AS rank_within_metric
FROM combined
ORDER BY metric_value DESC
LIMIT 100

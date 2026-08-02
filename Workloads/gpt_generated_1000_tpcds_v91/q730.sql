SELECT
    COALESCE(s.s_store_id, 'UNKNOWN_STORE') AS entity_id,
    d.d_date AS transaction_date,
    CASE t.metric_idx
        WHEN 1 THEN 'quantity'
        WHEN 2 THEN 'net_profit'
        WHEN 3 THEN 'ext_sales_price'
    END AS metric_name,
    t.metric_value AS metric_value
FROM store_sales ss
FULL OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
CROSS JOIN UNNEST(ARRAY[
    CAST(ss.ss_quantity AS double),
    CAST(ss.ss_net_profit AS double),
    CAST(ss.ss_ext_sales_price AS double)
]) WITH ORDINALITY AS t(metric_value, metric_idx)
WHERE (d.d_year = (SELECT MAX(d2.d_year) FROM date_dim d2) OR d.d_year IS NULL)

UNION ALL

SELECT
    COALESCE(cp.cp_catalog_page_id, 'UNKNOWN_PAGE') AS entity_id,
    d.d_date AS transaction_date,
    CASE t.metric_idx
        WHEN 1 THEN 'return_quantity'
        WHEN 2 THEN 'return_amount'
        WHEN 3 THEN 'fee'
    END AS metric_name,
    t.metric_value AS metric_value
FROM catalog_returns cr
FULL OUTER JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
CROSS JOIN UNNEST(ARRAY[
    CAST(cr.cr_return_quantity AS double),
    CAST(cr.cr_return_amount AS double),
    CAST(cr.cr_fee AS double)
]) WITH ORDINALITY AS t(metric_value, metric_idx)
WHERE (d.d_year = (SELECT MAX(d2.d_year) FROM date_dim d2) OR d.d_year IS NULL)

ORDER BY entity_id, transaction_date, metric_name
LIMIT 100

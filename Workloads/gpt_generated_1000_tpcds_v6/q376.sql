WITH filtered_returns AS (
    SELECT cr.cr_returned_date_sk,
           cr.cr_item_sk,
           cr.cr_warehouse_sk,
           cr.cr_return_amount,
           cr.cr_return_quantity,
           cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cr.cr_return_amount > 0
)
SELECT 
    w.w_warehouse_name,
    w.w_state,
    i.i_category,
    COUNT(*) AS return_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_quantity) AS avg_quantity,
    CASE 
        WHEN SUM(fr.cr_return_amount) > 10000 THEN 'HIGH'
        WHEN SUM(fr.cr_return_amount) > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS amount_bucket,
    SUBSTR(i.i_product_name, 1, 3) AS prod_prefix,
    REGEXP_EXTRACT(i.i_item_desc, '(\\d{3,})', 1) AS numeric_code,
    CASE 
        WHEN REGEXP_LIKE(w.w_suite_number, '^Suite[[:space:]]*[A-Z0-9]+') THEN 'SuiteMatch'
        ELSE 'NoMatch'
    END AS suite_flag,
    w.w_warehouse_name || ', ' || w.w_state AS warehouse_full
FROM filtered_returns fr
JOIN item i ON fr.cr_item_sk = i.i_item_sk
JOIN warehouse w ON fr.cr_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d ON fr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE 
    REGEXP_LIKE(i.i_item_desc, '\\d{3,}')
    AND w.w_suite_number LIKE 'Suite %'
    AND (wp.wp_url LIKE 'http://%/catalog%' OR wp.wp_url IS NULL)
GROUP BY 
    w.w_warehouse_name,
    w.w_state,
    i.i_category,
    SUBSTR(i.i_product_name, 1, 3),
    REGEXP_EXTRACT(i.i_item_desc, '(\\d{3,})', 1),
    CASE 
        WHEN REGEXP_LIKE(w.w_suite_number, '^Suite[[:space:]]*[A-Z0-9]+') THEN 'SuiteMatch'
        ELSE 'NoMatch'
    END
ORDER BY total_return_amount DESC
LIMIT 20

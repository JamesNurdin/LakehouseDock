WITH page_tokens AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_description,
        split(cp.cp_description, ' ') AS tokens
    FROM catalog_page cp
    WHERE cp.cp_start_date_sk >= 2450995
      AND cp.cp_description LIKE '%prisoners%'
)
SELECT
    w.w_state,
    pt.cp_department,
    concat(pt.cp_catalog_page_id, '_', cast(pt.cp_catalog_page_sk AS varchar)) AS full_page_key,
    token AS word,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    (SUM(cs.cs_net_paid) - COALESCE(SUM(cr.cr_return_amount), 0)) AS net_after_returns
FROM page_tokens pt
CROSS JOIN UNNEST(pt.tokens) AS t(token)
JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = pt.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE regexp_like(token, '^[A-Z][a-z]+$')
  AND w.w_state IN ('MO', 'GA')
GROUP BY
    w.w_state,
    pt.cp_department,
    concat(pt.cp_catalog_page_id, '_', cast(pt.cp_catalog_page_sk AS varchar)),
    token
ORDER BY net_after_returns DESC
LIMIT 100

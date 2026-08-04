WITH sampled_returns AS (
    SELECT cr.*
    FROM tpcds.catalog_returns cr
    TABLESAMPLE BERNOULLI (10)  -- sample 10% of rows for faster processing
    WHERE cr.cr_return_amount > 0
)
SELECT
    'warehouse'   AS entity_type,
    w.w_warehouse_name AS entity_name,
    SUM(DISTINCT cr.cr_return_amount)   AS sum_return_amount,
    COUNT(DISTINCT cr.cr_return_quantity) AS distinct_quantity_cnt
FROM sampled_returns cr
JOIN tpcds.warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY w.w_warehouse_name

UNION ALL

SELECT
    'call_center' AS entity_type,
    cc.cc_name    AS entity_name,
    SUM(DISTINCT cr.cr_return_amount)   AS sum_return_amount,
    COUNT(DISTINCT cr.cr_return_quantity) AS distinct_quantity_cnt
FROM sampled_returns cr
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY cc.cc_name

LIMIT 100

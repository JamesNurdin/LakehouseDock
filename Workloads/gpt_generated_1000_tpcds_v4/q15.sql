WITH filtered_returns AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_catalog_page_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_quantity,
        cr.cr_return_amt_inc_tax,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_addr_sk
    FROM catalog_returns cr
    WHERE cr.cr_refunded_customer_sk IN (577674, 931351, 3312919)
      AND cr.cr_catalog_page_sk BETWEEN 200 AND 400
      AND cr.cr_returning_addr_sk > 3000000
)
SELECT
    td.t_hour,
    td.t_shift,
    fr.cr_catalog_page_sk,
    COUNT(*) AS returns_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_tax) AS avg_return_tax,
    MIN(fr.cr_return_quantity) AS min_quantity,
    MAX(fr.cr_return_amt_inc_tax) AS max_amount_inc_tax,
    CASE
        WHEN fr.cr_return_amount > 150 THEN 'high'
        WHEN fr.cr_return_amount > 50 THEN 'medium'
        ELSE 'low'
    END AS amount_category,
    (SELECT MAX(cr3.cr_return_amount)
     FROM catalog_returns cr3
     WHERE cr3.cr_returned_time_sk = fr.cr_returned_time_sk) AS max_return_amount_same_time
FROM filtered_returns fr
JOIN time_dim td
  ON fr.cr_returned_time_sk = td.t_time_sk
WHERE td.t_sub_shift = 'morning'
  AND td.t_meal_time = 'breakfast'
  AND td.t_am_pm = 'AM'
GROUP BY
    td.t_hour,
    td.t_shift,
    fr.cr_catalog_page_sk,
    CASE
        WHEN fr.cr_return_amount > 150 THEN 'high'
        WHEN fr.cr_return_amount > 50 THEN 'medium'
        ELSE 'low'
    END,
    (SELECT MAX(cr3.cr_return_amount)
     FROM catalog_returns cr3
     WHERE cr3.cr_returned_time_sk = fr.cr_returned_time_sk)
ORDER BY total_return_amount DESC
LIMIT 100

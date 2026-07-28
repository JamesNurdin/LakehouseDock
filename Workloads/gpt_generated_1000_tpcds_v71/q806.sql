WITH
  returns AS (
    SELECT DISTINCT
      'Return' AS transaction_type,
      cp.cp_department AS department,
      CASE
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
      END AS gender_label,
      cr.cr_return_amount AS amount
    FROM catalog_returns cr
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Customer Not Satisfied'
      AND cr.cr_return_amount > 50
  ),
  sales AS (
    SELECT DISTINCT
      'Sale' AS transaction_type,
      cp.cp_department AS department,
      CASE
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
      END AS gender_label,
      cs.cs_net_paid AS amount
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_quantity > 5
  ),
  combined AS (
    SELECT * FROM returns
    UNION ALL
    SELECT * FROM sales
  )
SELECT
  transaction_type,
  department,
  gender_label,
  SUM(amount) AS total_amount
FROM combined
GROUP BY GROUPING SETS (
  (transaction_type, department, gender_label),
  (transaction_type, department),
  (transaction_type),
  ()
)
ORDER BY
  transaction_type,
  department,
  gender_label

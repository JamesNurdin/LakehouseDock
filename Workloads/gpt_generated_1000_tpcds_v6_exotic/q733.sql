WITH filtered_returns AS (
  SELECT
    cr.cr_call_center_sk,
    cr.cr_refunded_cdemo_sk,
    SUM(cr.cr_return_amount)                AS total_return_amount,
    COUNT(*)                                 AS return_cnt,
    SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_value_return
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND regexp_like(CAST(cr.cr_return_amount AS VARCHAR), '^[0-9]+\\.[0-9]{2}$')
  GROUP BY cr.cr_call_center_sk, cr.cr_refunded_cdemo_sk
)
SELECT
  cc.cc_call_center_sk,
  cc.cc_name,
  cd.cd_gender,
  cd.cd_marital_status,
  fr.total_return_amount,
  fr.return_cnt,
  (
    SELECT COALESCE(SUM(ss.ss_ext_sales_price), 0)
    FROM store_sales ss
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    WHERE ss.ss_cdemo_sk = cd.cd_demo_sk
      AND d2.d_year = 2002
  ) AS total_sales_amount,
  CASE
    WHEN (
      SELECT COALESCE(SUM(ss.ss_ext_sales_price), 0)
      FROM store_sales ss
      JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
      WHERE ss.ss_cdemo_sk = cd.cd_demo_sk
        AND d2.d_year = 2002
    ) = 0 THEN 0
    ELSE fr.total_return_amount /
         (
           SELECT COALESCE(SUM(ss.ss_ext_sales_price), 0)
           FROM store_sales ss
           JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
           WHERE ss.ss_cdemo_sk = cd.cd_demo_sk
             AND d2.d_year = 2002
         )
  END AS return_to_sales_ratio,
  CONCAT('CC_', CAST(cc.cc_call_center_sk AS VARCHAR))               AS cc_key,
  SUBSTRING(cc.cc_name, 1, 5)                                      AS name_prefix,
  CAST(regexp_extract(CAST(cc.cc_tax_percentage AS VARCHAR), '(\\d+\\.?\\d*)', 1) AS DOUBLE) AS tax_percent_extracted,
  (SELECT MAX(ib_upper_bound) FROM income_band)                    AS max_income_upper_bound
FROM filtered_returns fr
JOIN call_center cc ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_demographics cd ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE cc.cc_name LIKE '%Center%'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr_big
        WHERE cr_big.cr_call_center_sk = cc.cc_call_center_sk
          AND cr_big.cr_return_amount > 5000
      )
  AND SUBSTRING(cc.cc_name, 1, 3) = 'CA '
ORDER BY fr.total_return_amount DESC
LIMIT 100

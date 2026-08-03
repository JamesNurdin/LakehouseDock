WITH returns_female AS (
  SELECT
    cr.cr_order_number,
    cd.cd_gender,
    cd.cd_education_status,
    td.t_meal_time,
    cp.cp_catalog_page_id,
    cr.cr_return_amount,
    amt AS amount_value
  FROM catalog_returns cr
  JOIN customer_demographics cd
    ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  CROSS JOIN UNNEST(ARRAY[cr.cr_return_amount, cr.cr_fee]) AS t(amt)
  WHERE cd.cd_gender = 'F'
    AND cd.cd_education_status = 'Advanced Degree'
    AND td.t_meal_time = 'dinner'
    AND cp.cp_catalog_page_number BETWEEN 1 AND 10
    AND NOT EXISTS (
      SELECT 1
      FROM catalog_returns cr2
      WHERE cr2.cr_order_number = cr.cr_order_number
        AND cr2.cr_return_amount > 1000
    )
),
returns_male AS (
  SELECT
    cr.cr_order_number,
    cd.cd_gender,
    cd.cd_education_status,
    td.t_meal_time,
    cp.cp_catalog_page_id,
    cr.cr_return_amount,
    amt AS amount_value
  FROM catalog_returns cr
  JOIN customer_demographics cd
    ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  CROSS JOIN UNNEST(ARRAY[cr.cr_return_amount, cr.cr_fee]) AS t(amt)
  WHERE cd.cd_gender = 'M'
    AND cd.cd_education_status = 'Primary'
    AND td.t_meal_time = 'lunch'
    AND cp.cp_catalog_page_number BETWEEN 11 AND 20
    AND NOT EXISTS (
      SELECT 1
      FROM catalog_returns cr2
      WHERE cr2.cr_order_number = cr.cr_order_number
        AND cr2.cr_return_tax > 5.0
    )
)
SELECT
  cr_order_number,
  cd_gender,
  cd_education_status,
  t_meal_time,
  cp_catalog_page_id,
  cr_return_amount,
  amount_value
FROM (
  SELECT * FROM returns_female
  UNION ALL
  SELECT * FROM returns_male
) combined
ORDER BY cr_order_number, amount_value DESC
LIMIT 100

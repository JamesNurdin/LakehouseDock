WITH
  warehouse_us AS (
    SELECT w_warehouse_sk, w_city, w_state
    FROM warehouse
    WHERE w_country = 'United States'
  ),
  avg_return AS (
    SELECT avg(cr_return_amount) AS avg_amount
    FROM catalog_returns
  )
SELECT
  city,
  education_status,
  loss_category,
  amount_category,
  SUM(total_return_amount) AS sum_return_amount,
  COUNT(*) AS return_cnt
FROM (
  -- Refunded‑customer view
  SELECT
    w.w_city AS city,
    cd.cd_education_status AS education_status,
    CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_category,
    CASE WHEN cr.cr_return_amount > (SELECT avg_amount FROM avg_return) THEN 'Above Avg' ELSE 'Below Avg' END AS amount_category,
    cr.cr_return_amount AS total_return_amount
  FROM catalog_returns cr
  JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN warehouse_us w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE cr.cr_return_amount > 100
    AND cd.cd_education_status IN ('Primary', 'Secondary', 'Advanced Degree')

  UNION ALL

  -- Returning‑customer view
  SELECT
    w.w_city AS city,
    cd.cd_education_status AS education_status,
    CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_category,
    CASE WHEN cr.cr_return_amount > (SELECT avg_amount FROM avg_return) THEN 'Above Avg' ELSE 'Below Avg' END AS amount_category,
    cr.cr_return_amount AS total_return_amount
  FROM catalog_returns cr
  JOIN customer_demographics cd
    ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN warehouse_us w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE cr.cr_return_quantity >= 2
    AND cd.cd_credit_rating = 'Good'
) AS combined
GROUP BY CUBE (city, education_status, loss_category, amount_category)
HAVING SUM(total_return_amount) IS NOT NULL
ORDER BY city NULLS LAST, education_status NULLS LAST, loss_category, amount_category

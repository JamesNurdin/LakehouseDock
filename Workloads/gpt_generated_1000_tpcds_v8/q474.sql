WITH
  filtered_returns AS (
    SELECT
      cr.cr_returning_customer_sk,
      cr.cr_returning_cdemo_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_return_tax,
      cd.cd_gender,
      cd.cd_credit_rating
    FROM catalog_returns cr
    JOIN customer_demographics cd
      ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount > 100
      AND cd.cd_credit_rating = 'High Risk'
  ),
  eligible_customers AS (
    SELECT DISTINCT cr_returning_customer_sk
    FROM filtered_returns
    WHERE cr_return_quantity >= 2
    EXCEPT
    SELECT DISTINCT cr_returning_customer_sk
    FROM filtered_returns
    WHERE cr_return_amount > 500
  )
SELECT
  er.cr_returning_customer_sk,
  cd.cd_gender,
  cd.cd_credit_rating,
  er.total_return_amount,
  (
    SELECT AVG(cr3.cr_return_amount)
    FROM catalog_returns cr3
    WHERE cr3.cr_returning_customer_sk = er.cr_returning_customer_sk
  ) AS avg_return_amount,
  ROW_NUMBER() OVER (ORDER BY er.total_return_amount DESC) AS rn
FROM (
  SELECT
    fr.cr_returning_customer_sk,
    fr.cr_returning_cdemo_sk,
    SUM(fr.cr_return_amount) AS total_return_amount
  FROM filtered_returns fr
  WHERE fr.cr_returning_customer_sk IN (SELECT cr_returning_customer_sk FROM eligible_customers)
  GROUP BY fr.cr_returning_customer_sk, fr.cr_returning_cdemo_sk
) er
JOIN customer_demographics cd
  ON er.cr_returning_cdemo_sk = cd.cd_demo_sk
WHERE EXISTS (
  SELECT 1
  FROM catalog_returns cr2
  WHERE cr2.cr_returning_customer_sk = er.cr_returning_customer_sk
    AND cr2.cr_return_tax > 5
)
ORDER BY er.total_return_amount DESC
OFFSET 10 LIMIT 100

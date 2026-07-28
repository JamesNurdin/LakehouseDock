WITH joined_data AS (
  SELECT
    sr.sr_return_amt,
    sr.sr_fee,
    cd.cd_gender,
    cd.cd_credit_rating,
    cd.cd_dep_employed_count,
    CONCAT(cd.cd_gender, '-', cd.cd_credit_rating) AS gender_credit_key
  FROM store_returns sr
  JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE regexp_like(cd.cd_credit_rating, '^A[0-9]{2}$')
    AND cd.cd_gender LIKE 'M%'
)
SELECT
  gender_credit_key,
  CASE WHEN sr_fee > 30 THEN 'High' ELSE 'Low' END AS fee_category,
  COUNT(*) AS return_count,
  SUM(sr_return_amt) AS total_return_amt,
  AVG(sr_return_amt) AS avg_return_amt,
  CASE WHEN AVG(sr_return_amt) > (SELECT AVG(sr_return_amt) FROM store_returns)
       THEN 'Above Avg' ELSE 'Below Avg' END AS avg_vs_global
FROM joined_data
WHERE cd_dep_employed_count > 0
GROUP BY gender_credit_key, CASE WHEN sr_fee > 30 THEN 'High' ELSE 'Low' END

UNION ALL

SELECT
  gender_credit_key,
  CASE WHEN sr_fee > 30 THEN 'High' ELSE 'Low' END AS fee_category,
  COUNT(*) AS return_count,
  SUM(sr_return_amt) AS total_return_amt,
  AVG(sr_return_amt) AS avg_return_amt,
  CASE WHEN AVG(sr_return_amt) > (SELECT AVG(sr_return_amt) FROM store_returns)
       THEN 'Above Avg' ELSE 'Below Avg' END AS avg_vs_global
FROM joined_data
WHERE cd_dep_employed_count = 0
GROUP BY gender_credit_key, CASE WHEN sr_fee > 30 THEN 'High' ELSE 'Low' END
ORDER BY total_return_amt DESC
LIMIT 100

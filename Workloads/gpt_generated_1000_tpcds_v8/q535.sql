SELECT
    cd_gender,
    cd_credit_rating,
    AVG(cd_purchase_estimate) AS avg_estimate
FROM tpcds.customer_demographics
WHERE cd_credit_rating = 'Low Risk'
  AND cd_purchase_estimate > 3000
GROUP BY cd_gender, cd_credit_rating
LIMIT 100

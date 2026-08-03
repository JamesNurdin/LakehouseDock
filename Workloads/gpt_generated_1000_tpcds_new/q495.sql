SELECT
  sr.sr_return_amt,
  sr.sr_return_tax,
  cd.cd_gender,
  cd.cd_education_status
FROM store_returns AS sr
JOIN customer_demographics AS cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
WHERE sr.sr_return_tax > 5.00
  AND cd.cd_education_status = 'College'

SELECT CASE WHEN wr.wr_return_amt > 134.40 THEN 'High' ELSE 'Low' END AS return_category,
       (wr.wr_return_quantity * wr.wr_return_amt) AS total_return_amount,
       (wr.wr_return_tax + wr.wr_fee) AS tax_and_fee,
       CASE WHEN cd.cd_gender = 'F' THEN 'SameGender' ELSE 'OtherGender' END AS gender_flag,
       wr.wr_returned_date_sk,
       cd.cd_education_status
FROM web_returns wr
JOIN customer_demographics cd
  ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE wr.wr_return_quantity > 30
  AND cd.cd_marital_status = 'U'

SELECT cd.cd_gender,
       SUM(wr.wr_return_amt) AS total_return_amount
FROM web_returns wr
JOIN customer_demographics cd
  ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE wr.wr_returned_date_sk BETWEEN 2451180 AND 2451182
GROUP BY cd.cd_gender
ORDER BY total_return_amount DESC

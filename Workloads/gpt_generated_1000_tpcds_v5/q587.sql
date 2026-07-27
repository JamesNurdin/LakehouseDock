SELECT
  cd.cd_gender,
  cd.cd_credit_rating,
  SUM(ws.ws_net_paid) AS total_net_paid
FROM web_sales ws
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_credit_rating = 'Good'
  AND ws.ws_ext_list_price > 5000
GROUP BY cd.cd_gender, cd.cd_credit_rating
LIMIT 100

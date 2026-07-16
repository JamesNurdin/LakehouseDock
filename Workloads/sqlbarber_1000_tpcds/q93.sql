SELECT hd_income_band_sk,
       SUM(ws_net_paid) AS total_net_paid
FROM web_sales
JOIN household_demographics
  ON web_sales.ws_bill_hdemo_sk = household_demographics.hd_demo_sk
WHERE hd_buy_potential = '1001-5000      '
GROUP BY hd_income_band_sk
ORDER BY total_net_paid DESC
LIMIT 10

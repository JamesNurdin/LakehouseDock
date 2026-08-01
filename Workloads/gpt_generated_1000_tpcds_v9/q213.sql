SELECT
    d.d_date AS return_date,
    cd.cd_gender AS gender,
    'store' AS return_source,
    sum(sr.sr_return_amt) AS total_return_amount,
    sum(sr.sr_return_quantity) AS total_return_quantity
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND sr.sr_return_amt > 1000
GROUP BY d.d_date, cd.cd_gender

UNION ALL

SELECT
    d.d_date AS return_date,
    cd.cd_gender AS gender,
    'web' AS return_source,
    sum(wr.wr_return_amt) AS total_return_amount,
    sum(wr.wr_return_quantity) AS total_return_quantity
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND wr.wr_return_amt > 1000
GROUP BY d.d_date, cd.cd_gender

ORDER BY return_date, gender, return_source

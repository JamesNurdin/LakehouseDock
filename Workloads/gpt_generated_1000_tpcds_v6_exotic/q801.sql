SELECT
    wr_returning_customer_sk,
    COUNT(*) AS returns_cnt,
    SUM(wr_return_amt_inc_tax) AS total_return_inc_tax
FROM tpcds.web_returns
WHERE wr_returning_customer_sk = 79514
  AND wr_return_amt_inc_tax > 100
GROUP BY wr_returning_customer_sk
ORDER BY total_return_inc_tax DESC

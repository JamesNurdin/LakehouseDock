SELECT
    cr_returning_hdemo_sk,
    COUNT(*) AS returns_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_tax) AS avg_return_tax
FROM tpcds.catalog_returns
WHERE cr_return_tax > 100
  AND cr_returning_hdemo_sk IN (848, 1235)
GROUP BY cr_returning_hdemo_sk
ORDER BY total_return_amount DESC

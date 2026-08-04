SELECT d.d_year,
       d.d_month_seq,
       SUM(wr.wr_return_amt) AS total_return_amt,
       COUNT(*) AS returns_count
FROM tpcds.web_returns wr
JOIN tpcds.date_dim d
  ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 1915
  AND d.d_moy = 10
GROUP BY d.d_year, d.d_month_seq
ORDER BY d.d_month_seq

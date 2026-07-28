SELECT
    i.i_brand,
    SUM(wr.wr_return_amt) AS total_return_amt,
    COUNT(*) AS return_cnt
FROM tpcds.item AS i
JOIN tpcds.web_returns AS wr
    ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_container = 'Unknown'
  AND i.i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
GROUP BY i.i_brand
ORDER BY total_return_amt DESC

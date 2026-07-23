SELECT
    wr_order_number,
    wr_return_amt,
    wr_return_tax,
    wr_return_quantity,
    wr_returning_hdemo_sk
FROM tpcds.web_returns
WHERE wr_web_page_sk = 673
  AND wr_reversed_charge > 200
LIMIT 100

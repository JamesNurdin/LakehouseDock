WITH recent_store_returns AS (
  SELECT sr.sr_store_sk,
         SUM(sr.sr_return_amt_inc_tax) AS total_return,
         COUNT(*) AS return_cnt,
         AVG(sr.sr_return_tax) AS avg_tax
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
  GROUP BY sr.sr_store_sk
),
unmatched_store_keys AS (
  SELECT sr.sr_store_sk
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
  EXCEPT
  SELECT ws.ws_bill_customer_sk
  FROM web_sales ws
  JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
  WHERE d2.d_year = 2000
)
SELECT r.sr_store_sk,
       r.total_return,
       r.return_cnt,
       r.avg_tax,
       (SELECT MAX(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = r.sr_store_sk) AS max_web_sales_price
FROM recent_store_returns r
JOIN unmatched_store_keys u ON r.sr_store_sk = u.sr_store_sk
WHERE r.sr_store_sk NOT IN (
    SELECT sr3.sr_store_sk
    FROM store_returns sr3
    JOIN date_dim d3 ON sr3.sr_returned_date_sk = d3.d_date_sk
    WHERE d3.d_year = 1999 AND sr3.sr_return_tax > 120
)
ORDER BY r.total_return DESC
LIMIT 100

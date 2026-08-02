WITH store_return_agg AS (
  SELECT c.c_customer_sk,
         c.c_customer_id,
         SUM(sr.sr_return_amt) AS total_return_amt,
         COUNT(*) AS return_cnt,
         ARRAY_AGG(sr.sr_return_amt) AS return_amt_array
  FROM store_returns sr
  JOIN store_sales ss
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
  WHERE sr.sr_return_quantity > 5
  GROUP BY c.c_customer_sk, c.c_customer_id
),
store_return_expanded AS (
  SELECT sa.c_customer_sk,
         sa.c_customer_id,
         sa.total_return_amt,
         sa.return_cnt,
         amt AS individual_return_amt
  FROM store_return_agg sa
  CROSS JOIN UNNEST(sa.return_amt_array) AS t(amt)
),
web_return_agg AS (
  SELECT c.c_customer_sk,
         c.c_customer_id,
         SUM(wr.wr_return_amt) AS total_return_amt,
         COUNT(*) AS return_cnt,
         ARRAY_AGG(wr.wr_return_amt) AS return_amt_array
  FROM web_returns wr
  JOIN web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  JOIN customer c
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE wr.wr_return_quantity > 5
  GROUP BY c.c_customer_sk, c.c_customer_id
),
web_return_expanded AS (
  SELECT wa.c_customer_sk,
         wa.c_customer_id,
         wa.total_return_amt,
         wa.return_cnt,
         amt AS individual_return_amt
  FROM web_return_agg wa
  CROSS JOIN UNNEST(wa.return_amt_array) AS t(amt)
)
SELECT DISTINCT
       src.c_customer_id,
       src.c_customer_sk,
       src.total_return_amt,
       src.return_cnt,
       src.individual_return_amt,
       src.source_type
FROM (
  SELECT c_customer_sk,
         c_customer_id,
         total_return_amt,
         return_cnt,
         individual_return_amt,
         'store' AS source_type
  FROM store_return_expanded
  UNION ALL
  SELECT c_customer_sk,
         c_customer_id,
         total_return_amt,
         return_cnt,
         individual_return_amt,
         'web' AS source_type
  FROM web_return_expanded
) src
WHERE src.total_return_amt > 1000
ORDER BY src.total_return_amt DESC
LIMIT 100

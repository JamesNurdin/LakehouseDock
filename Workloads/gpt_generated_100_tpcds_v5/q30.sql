WITH store_ret AS (
   SELECT r.r_reason_desc AS reason_desc,
          SUM(sr.sr_return_amt_inc_tax) AS total_return,
          COUNT(*) AS cnt,
          ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC) AS rn
   FROM store_returns sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE sr.sr_returned_date_sk BETWEEN 2451500 AND 2452000
   GROUP BY r.r_reason_desc
   HAVING SUM(sr.sr_return_amt_inc_tax) > 5000
),
web_ret AS (
   SELECT r.r_reason_desc AS reason_desc,
          SUM(wr.wr_return_amt_inc_tax) AS total_return,
          COUNT(*) AS cnt,
          ROW_NUMBER() OVER (PARTITION BY r.r_reason_desc ORDER BY SUM(wr.wr_return_amt_inc_tax) DESC) AS rn
   FROM web_returns wr
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
                    AND wr.wr_order_number = ws.ws_order_number
   WHERE wr.wr_returned_date_sk BETWEEN 2451500 AND 2452000
     AND EXISTS (
         SELECT 1 FROM web_sales ws2
         WHERE ws2.ws_order_number = wr.wr_order_number
           AND ws2.ws_ext_sales_price > 1000
     )
   GROUP BY r.r_reason_desc
   HAVING SUM(wr.wr_return_amt_inc_tax) > 5000
)
SELECT DISTINCT reason_desc,
       total_return,
       cnt
FROM (
   SELECT reason_desc,
          total_return,
          cnt
   FROM store_ret
   WHERE rn = 1
   UNION ALL
   SELECT reason_desc,
          total_return,
          cnt
   FROM web_ret
   WHERE rn = 1
) AS combined
ORDER BY total_return DESC
LIMIT 100

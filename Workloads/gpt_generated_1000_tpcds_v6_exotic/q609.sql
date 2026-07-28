SELECT c_customer_id,
       c_first_name,
       c_last_name,
       total_return_amount,
       source
FROM (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           SUM(cr.cr_return_amount) AS total_return_amount,
           'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs
          JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
          WHERE cs.cs_bill_customer_sk = c.c_customer_sk
            AND d2.d_year = 2000
      )
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           SUM(wr.wr_return_amt) AS total_return_amount,
           'web' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
          WHERE ws.ws_bill_customer_sk = c.c_customer_sk
            AND d2.d_year = 2000
      )
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
) AS combined
ORDER BY total_return_amount DESC, source

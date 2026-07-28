WITH store_summary AS (
        SELECT
            c.c_customer_id,
            SUM(ss.ss_net_paid) AS total_sales,
            COUNT(*) AS txn_count,
            'store' AS source_type
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
          AND EXISTS (
                SELECT 1
                FROM store_returns sr
                WHERE sr.sr_customer_sk = c.c_customer_sk
                  AND sr.sr_returned_date_sk = d.d_date_sk
                  AND sr.sr_return_amt > 0
          )
        GROUP BY c.c_customer_id
    ),
    web_summary AS (
        SELECT
            c.c_customer_id,
            SUM(ws.ws_net_paid) AS total_sales,
            COUNT(*) AS txn_count,
            'web' AS source_type
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
          AND EXISTS (
                SELECT 1
                FROM web_returns wr
                WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
                  AND wr.wr_returned_date_sk = d.d_date_sk
                  AND wr.wr_return_amt > 0
          )
        GROUP BY c.c_customer_id
    )
SELECT *
FROM store_summary
UNION ALL
SELECT *
FROM web_summary
ORDER BY total_sales DESC
LIMIT 100

WITH store_agg AS (
    SELECT c.c_customer_id,
           SUM(ss.ss_net_paid) AS total_store_sales,
           COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
    GROUP BY c.c_customer_id
),
web_agg AS (
    SELECT c.c_customer_id,
           SUM(ws.ws_net_paid) AS total_web_sales,
           COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
    GROUP BY c.c_customer_id
),
combined AS (
    SELECT sa.c_customer_id,
           sa.total_store_sales AS total_sales,
           sa.store_txn_cnt AS txn_cnt,
           'store' AS channel
    FROM store_agg sa
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
        JOIN customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
        WHERE c2.c_customer_id = sa.c_customer_id
          AND dr.d_year = 2002
    )
    UNION ALL
    SELECT wa.c_customer_id,
           wa.total_web_sales AS total_sales,
           wa.web_txn_cnt AS txn_cnt,
           'web' AS channel
    FROM web_agg wa
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN date_dim dw ON wr.wr_returned_date_sk = dw.d_date_sk
        JOIN customer c3 ON wr.wr_refunded_customer_sk = c3.c_customer_sk
        WHERE c3.c_customer_id = wa.c_customer_id
          AND dw.d_year = 2002
    )
)
SELECT c_customer_id,
       total_sales,
       txn_cnt,
       channel
FROM combined
ORDER BY total_sales DESC
LIMIT 100

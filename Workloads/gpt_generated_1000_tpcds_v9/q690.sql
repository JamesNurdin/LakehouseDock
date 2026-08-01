WITH store_ret AS (
    SELECT
        sr.sr_customer_sk,
        c.c_customer_id,
        c.c_last_name,
        SUM(sr.sr_return_amt) AS total_return_amount,
        'Store' AS channel,
        (SELECT AVG(sr2.sr_return_amt)
         FROM store_returns sr2
         JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
         WHERE d2.d_year = 2022) AS avg_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
    GROUP BY sr.sr_customer_sk, c.c_customer_id, c.c_last_name
),

catalog_ret AS (
    SELECT
        cr.cr_refunded_customer_sk AS sr_customer_sk,
        c.c_customer_id,
        c.c_last_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        'Catalog' AS channel,
        (SELECT AVG(cr3.cr_return_amount)
         FROM catalog_returns cr3
         JOIN date_dim d3 ON cr3.cr_returned_date_sk = d3.d_date_sk
         WHERE d3.d_year = 2022) AS avg_return_amt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2022
      AND w.w_country = 'United States'
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr2
          JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
          WHERE sr2.sr_customer_sk = cr.cr_refunded_customer_sk
            AND d2.d_year = 2022
      )
    GROUP BY cr.cr_refunded_customer_sk, c.c_customer_id, c.c_last_name
),

combined AS (
    SELECT
        u.sr_customer_sk,
        u.c_customer_id,
        u.c_last_name,
        u.total_return_amount,
        u.channel,
        u.avg_return_amt,
        RANK() OVER (PARTITION BY u.channel ORDER BY u.total_return_amount DESC) AS amount_rank
    FROM (
        SELECT
            sr_customer_sk,
            c_customer_id,
            c_last_name,
            total_return_amount,
            channel,
            avg_return_amt
        FROM store_ret
        UNION ALL
        SELECT
            sr_customer_sk,
            c_customer_id,
            c_last_name,
            total_return_amount,
            channel,
            avg_return_amt
        FROM catalog_ret
    ) u
)

SELECT
    sr_customer_sk,
    c_customer_id,
    c_last_name,
    total_return_amount,
    channel,
    avg_return_amt,
    amount_rank
FROM combined
ORDER BY total_return_amount DESC
LIMIT 100

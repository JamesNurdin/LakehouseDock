WITH
  customer_sales AS (
    SELECT ss.ss_customer_sk AS customer_sk,
           SUM(ss.ss_net_paid) AS total_spent
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY ss.ss_customer_sk
  ),
  store_ret AS (
    SELECT sr.sr_returned_date_sk AS date_sk,
           d.d_date,
           sr.sr_customer_sk AS customer_sk,
           sr.sr_return_quantity,
           sr.sr_return_amt AS return_amount,
           sr.sr_reason_sk AS reason_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
  ),
  catalog_ret AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           d.d_date,
           cr.cr_refunded_customer_sk AS customer_sk,
           cr.cr_return_quantity,
           cr.cr_return_amount AS return_amount,
           cr.cr_reason_sk AS reason_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
  ),
  combined_ret AS (
    SELECT COALESCE(sr.date_sk, cr.date_sk)                         AS date_sk,
           COALESCE(sr.d_date, cr.d_date)                         AS return_date,
           COALESCE(sr.customer_sk, cr.customer_sk)               AS customer_sk,
           CASE
               WHEN sr.return_amount IS NOT NULL THEN 'store'
               WHEN cr.return_amount IS NOT NULL THEN 'catalog'
               ELSE 'unknown'
           END                                                    AS source,
           COALESCE(sr.return_amount, cr.return_amount)           AS return_amount,
           COALESCE(sr.reason_sk, cr.reason_sk)                   AS reason_sk
    FROM   store_ret sr
    FULL   OUTER JOIN catalog_ret cr
           ON sr.date_sk = cr.date_sk
  )
SELECT cr.date_sk,
       cr.return_date,
       cr.customer_sk,
       cr.source,
       cr.return_amount,
       r.r_reason_desc,
       (SELECT cs.total_spent
        FROM   customer_sales cs
        WHERE  cs.customer_sk = cr.customer_sk)                         AS customer_total_spent
FROM   combined_ret cr
LEFT   JOIN reason r
       ON cr.reason_sk = r.r_reason_sk
WHERE  cr.return_amount > 0
UNION ALL
SELECT wr.wr_returned_date_sk                               AS date_sk,
       d2.d_date                                            AS return_date,
       wr.wr_refunded_customer_sk                           AS customer_sk,
       'web'                                                AS source,
       wr.wr_return_amt                                    AS return_amount,
       r2.r_reason_desc,
       (SELECT cs2.total_spent
        FROM   customer_sales cs2
        WHERE  cs2.customer_sk = wr.wr_refunded_customer_sk)   AS customer_total_spent
FROM   web_returns wr
JOIN   date_dim d2
       ON wr.wr_returned_date_sk = d2.d_date_sk
LEFT   JOIN reason r2
       ON wr.wr_reason_sk = r2.r_reason_sk
WHERE  wr.wr_return_amt > 0
LIMIT 100

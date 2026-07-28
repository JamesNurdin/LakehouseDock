WITH return_flags AS (
    SELECT
        sr.sr_customer_sk,
        COUNT(*) AS return_cnt,
        MAX(sr.sr_net_loss) AS max_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY sr.sr_customer_sk
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    REGEXP_EXTRACT(c.c_email_address, '@(.*)$') AS email_domain,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(ss.ss_ticket_number) AS num_sales,
    AVG(ss.ss_quantity) AS avg_quantity
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN return_flags rf ON c.c_customer_sk = rf.sr_customer_sk
WHERE d.d_year = 2002
  AND REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
  AND c.c_first_name LIKE 'A%'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_net_loss > 1000
    )
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address
ORDER BY total_profit DESC
LIMIT 100

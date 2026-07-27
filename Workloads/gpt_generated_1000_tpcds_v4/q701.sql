WITH preferred_refunds AS (
    SELECT
        c.c_customer_id,
        SUM(sr.sr_refunded_cash) AS total_refunded,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_day = 27
    GROUP BY c.c_customer_id
    HAVING SUM(sr.sr_refunded_cash) > 1000
)
SELECT
    pr.c_customer_id,
    pr.total_refunded,
    pr.return_cnt,
    CAST('Preferred' AS varchar) AS segment
FROM preferred_refunds pr
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    JOIN customer c2 ON sr2.sr_customer_sk = c2.c_customer_sk
    WHERE c2.c_customer_id = pr.c_customer_id
      AND sr2.sr_store_credit > 200
)
UNION ALL
SELECT
    c.c_customer_id,
    SUM(sr.sr_refunded_cash) AS total_refunded,
    COUNT(*) AS return_cnt,
    CAST('Other' AS varchar) AS segment
FROM store_returns sr
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'N'
  AND sr.sr_refunded_cash > 50
GROUP BY c.c_customer_id
HAVING COUNT(*) >= 2
LIMIT 100

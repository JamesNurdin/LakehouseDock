WITH customer_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_first_shipto_date_sk,
        sr.sr_return_amt_inc_tax AS sr_return_amt_inc_tax,
        sr.sr_store_credit AS sr_store_credit,
        sr.sr_return_quantity,
        wp.wp_web_page_id,
        wp.wp_link_count,
        wp.wp_max_ad_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY sr.sr_return_amt_inc_tax DESC) AS rn,
        CASE
            WHEN sr.sr_store_credit > 200 THEN 'HIGH'
            WHEN sr.sr_store_credit > 100 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS credit_category,
        (
            SELECT AVG(sr2.sr_store_credit)
            FROM store_returns sr2
            WHERE sr2.sr_customer_sk = c.c_customer_sk
        ) AS avg_customer_credit
    FROM customer c
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_first_shipto_date_sk IN (2451883, 2450041, 2451827, 2449580)
      AND sr.sr_store_credit > 50
      AND sr.sr_return_amt_inc_tax < 500
      AND wp.wp_link_count >= 5
      AND wp.wp_type = 'product'
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    c_first_shipto_date_sk,
    sr_return_amt_inc_tax,
    sr_store_credit,
    credit_category,
    avg_customer_credit,
    rn
FROM customer_returns
WHERE EXISTS (
    SELECT 1
    FROM web_page wp2
    WHERE wp2.wp_customer_sk = customer_returns.c_customer_sk
      AND wp2.wp_max_ad_count > 2
)
ORDER BY sr_return_amt_inc_tax DESC
LIMIT 100

WITH filtered_customers AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_first_name,
        c_last_name,
        c_email_address
    FROM customer
    WHERE regexp_like(c_customer_id, '^AAAA')
      AND c_email_address LIKE '%@example.com'
)
SELECT
    fc.c_customer_sk,
    fc.c_customer_id,
    concat(fc.c_first_name, ' ', fc.c_last_name) AS customer_name,
    regexp_extract(r.r_reason_desc, '^([A-Za-z]+)', 1) AS reason_category,
    COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(sr.sr_refunded_cash) AS total_refunded,
    (
        SELECT max(sr2.sr_return_tax)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = fc.c_customer_sk
    ) AS max_return_tax
FROM filtered_customers fc
JOIN store_sales ss
    ON ss.ss_customer_sk = fc.c_customer_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_customer_sk = fc.c_customer_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr.sr_return_tax > 5.00
GROUP BY GROUPING SETS (
    (fc.c_customer_sk, fc.c_customer_id, fc.c_first_name, fc.c_last_name, r.r_reason_desc),
    (fc.c_customer_sk, fc.c_customer_id, fc.c_first_name, fc.c_last_name),
    ()
)
ORDER BY total_profit DESC, fc.c_customer_id
LIMIT 100

WITH cust_sales AS (
    SELECT c_customer_sk, c_preferred_cust_flag, c_first_name, c_last_name
    FROM customer
),
cust_sales2 AS (
    SELECT c_customer_sk, c_birth_country
    FROM customer
),
cust_returns AS (
    SELECT c_customer_sk, c_birth_year
    FROM customer
),
cust_returning AS (
    SELECT c_customer_sk, c_email_address
    FROM customer
),
reason_sr AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
),
reason_wr AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
)
SELECT
    cs.c_preferred_cust_flag,
    cs2.c_birth_country,
    r1.r_reason_desc AS store_return_reason,
    r2.r_reason_desc AS web_return_reason,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_tickets,
    SUM(ss.ss_net_paid) AS total_sales_net_paid,
    SUM(sr.sr_net_loss) AS total_store_return_net_loss,
    SUM(wr.wr_net_loss) AS total_web_return_net_loss,
    COUNT(DISTINCT cr.c_customer_sk) AS distinct_store_return_customers,
    COUNT(DISTINCT c_ret.c_customer_sk) AS distinct_web_returning_customers
FROM store_sales ss
JOIN cust_sales cs
    ON ss.ss_customer_sk = cs.c_customer_sk
JOIN cust_sales2 cs2
    ON ss.ss_customer_sk = cs2.c_customer_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
JOIN store_sales ss2
    ON sr.sr_ticket_number = ss2.ss_ticket_number
JOIN cust_returns cr
    ON sr.sr_customer_sk = cr.c_customer_sk
JOIN reason_sr r1
    ON sr.sr_reason_sk = r1.r_reason_sk
JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = cr.c_customer_sk
JOIN reason_wr r2
    ON wr.wr_reason_sk = r2.r_reason_sk
JOIN cust_returning c_ret
    ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
GROUP BY
    cs.c_preferred_cust_flag,
    cs2.c_birth_country,
    r1.r_reason_desc,
    r2.r_reason_desc
ORDER BY total_sales_net_paid DESC
LIMIT 100

WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        c.c_preferred_cust_flag,
        c.c_birth_country,
        CASE
            WHEN REGEXP_LIKE(c.c_email_address, '\\.org$') THEN 'ORG'
            ELSE 'OTH'
        END AS email_domain_type
    FROM tpcds.customer c
    WHERE REGEXP_LIKE(c.c_email_address, '\\.org$')
      AND c.c_first_name LIKE 'A%'
      AND NOT EXISTS (
          SELECT 1
          FROM tpcds.catalog_returns cr
          WHERE cr.cr_returning_customer_sk = c.c_customer_sk
             OR cr.cr_refunded_customer_sk = c.c_customer_sk
      )
),
sales AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        p.p_promo_name AS promo_name,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        CASE WHEN ws.ws_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
    FROM tpcds.web_sales ws
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_ext_sales_price > 500
)
SELECT
    fc.email_domain_type,
    fc.c_preferred_cust_flag,
    s.promo_name,
    SUM(s.ws_net_paid) AS total_net_paid,
    SUM(s.ws_net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count,
    SUM(CASE WHEN s.profit_flag = 'PROFIT' THEN 1 ELSE 0 END) AS profit_transactions,
    AVG(s.ws_ext_sales_price) AS avg_ext_sales_price
FROM filtered_customers fc
JOIN sales s
    ON s.customer_sk = fc.c_customer_sk
GROUP BY CUBE (fc.email_domain_type, fc.c_preferred_cust_flag, s.promo_name)
ORDER BY total_net_paid DESC
LIMIT 100

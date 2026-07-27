WITH sales_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        d.d_year
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2020
      AND regexp_like(c.c_email_address, '@[^@]+\\.com$')
      AND c.c_first_name LIKE 'A%'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
      )
)
SELECT
    s.cs_bill_customer_sk AS customer_sk,
    concat(s.c_first_name, ' ', s.c_last_name) AS full_name,
    regexp_extract(s.c_email_address, '@(.*)$', 1) AS email_domain,
    COUNT(DISTINCT s.cs_order_number) AS orders_cnt,
    SUM(s.cs_net_profit) AS total_net_profit,
    COALESCE((
        SELECT SUM(cr.cr_return_amount)
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = s.cs_bill_customer_sk
    ), 0) AS total_return_amount
FROM sales_filtered s
GROUP BY
    s.cs_bill_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.c_email_address
HAVING SUM(s.cs_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100

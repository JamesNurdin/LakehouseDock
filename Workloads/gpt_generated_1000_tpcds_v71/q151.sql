WITH sales_filtered AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        ws.ws_bill_customer_sk,
        ws.ws_ship_mode_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_ext_sales_price > 0
),
customer_sales AS (
    SELECT
        sm.sm_code,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cs.ws_ext_sales_price,
        d.d_date,
        -- extract the part before @
        substring(c.c_email_address FROM 1 FOR position('@' IN c.c_email_address) - 1) AS email_user,
        -- extract domain using regexp_extract
        regexp_extract(c.c_email_address, '@([^@]+)$', 1) AS email_domain,
        -- full name concatenation
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        -- scalar subquery: average sales price for the same day
        (SELECT avg(ws2.ws_ext_sales_price)
         FROM web_sales ws2
         WHERE ws2.ws_sold_date_sk = cs.ws_sold_date_sk) AS avg_daily_price
    FROM sales_filtered cs
    JOIN customer c ON cs.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON cs.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d ON cs.ws_sold_date_sk = d.d_date_sk
    WHERE regexp_like(c.c_email_address, '^.+@example\\.com$')
      AND sm.sm_code LIKE 'A%'
      -- anti‑join: exclude customers who have any catalog return
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
            AND cr.cr_returned_date_sk = cs.ws_sold_date_sk
      )
)
SELECT DISTINCT
    sm_code,
    email_user,
    full_name,
    COUNT(*) AS order_count,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(avg_daily_price) AS avg_daily_price_across_days
FROM customer_sales
GROUP BY sm_code, email_user, full_name
ORDER BY total_sales DESC
LIMIT 100

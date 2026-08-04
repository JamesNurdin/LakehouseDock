/*
Goal: Identify high‑profit web sites for the year 2022 and list customers who placed web sales but never issued a return, applying string‑pattern filters, sampling, and pagination.
*/
WITH sampled_sales AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2022
    )
),
sales_join AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        d.d_date,
        ws.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_web_site_sk,
        wsite.web_site_id,
        wsite.web_name,
        wsite.web_company_name,
        hd.hd_income_band_sk,
        ib.ib_upper_bound
    FROM sampled_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(wsite.web_name, '^A')               -- web site name starts with "A"
      AND c.c_first_name LIKE 'J%'                       -- first name begins with J
      AND ib.ib_upper_bound >= 100000                     -- high income band
),
sales_agg AS (
    SELECT
        wsite.web_site_id,
        wsite.web_name,
        COUNT(DISTINCT sj.ws_order_number) AS orders,
        SUM(sj.ws_net_paid) AS total_net_paid,
        SUM(sj.ws_net_profit) AS total_profit,
        AVG(sj.ws_quantity) AS avg_quantity,
        CONCAT('Site_', wsite.web_site_id) AS site_label,
        regexp_extract(wsite.web_company_name, '([a-z]+)', 1) AS company_prefix
    FROM sales_join sj
    JOIN web_site wsite ON sj.ws_web_site_sk = wsite.web_site_sk
    GROUP BY wsite.web_site_id, wsite.web_name, wsite.web_company_name
),
returns_customers AS (
    SELECT DISTINCT wr.wr_returning_customer_sk AS c_customer_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
),
sales_customers AS (
    SELECT DISTINCT ws.ws_bill_customer_sk AS c_customer_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
),
customers_no_returns AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_email_address
    FROM customer c
    JOIN sales_customers sc ON c.c_customer_sk = sc.c_customer_sk
    EXCEPT
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_email_address
    FROM customer c
    JOIN returns_customers rc ON c.c_customer_sk = rc.c_customer_sk
)
SELECT
    a.web_site_id,
    a.web_name,
    a.orders,
    a.total_net_paid,
    a.total_profit,
    a.avg_quantity,
    a.site_label,
    a.company_prefix,
    cnr.c_customer_sk,
    cnr.c_first_name,
    cnr.c_last_name,
    cnr.c_email_address
FROM sales_agg a
JOIN customers_no_returns cnr ON cnr.c_email_address LIKE '%@example.com'   -- filter email domain
ORDER BY a.total_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

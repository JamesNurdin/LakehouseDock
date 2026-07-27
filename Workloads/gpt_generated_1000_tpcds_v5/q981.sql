/*
Goal: Identify customers (with @example.com email) who either bought items whose brand starts with 'A' and description contains "special" on web sites whose name includes "Online", or returned items whose category starts with "Elect" and description contains "refurb". For each customer we compute total sales/returns amount and order count, show a concatenated full name, email domain, and related surrogate date key, then list the distinct rows ordered by total amount.
*/
WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain,
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS orders_cnt
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE regexp_like(i.i_brand, '^A')                         -- brand starts with A
      AND i.i_item_desc LIKE '%special%'                       -- description contains "special"
      AND w.web_name LIKE '%Online%'                           -- web site name pattern
      AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk
),
returns_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain,
        NULL AS ws_web_site_sk,
        sr.sr_returned_date_sk AS ws_sold_date_sk,
        SUM(sr.sr_return_amt) AS total_sales,
        COUNT(*) AS orders_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_category, '^Elect')                  -- category starts with Elect
      AND i.i_item_desc LIKE '%refurb%'
      AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        sr.sr_returned_date_sk
)
SELECT DISTINCT
    customer_id,
    full_name,
    email_domain,
    web_site_sk,
    ws_sold_date_sk AS sold_date_sk,
    total_sales,
    orders_cnt
FROM (
    SELECT
        c_customer_id AS customer_id,
        full_name,
        email_domain,
        ws_web_site_sk AS web_site_sk,
        ws_sold_date_sk,
        total_sales,
        orders_cnt
    FROM sales_agg
    UNION ALL
    SELECT
        c_customer_id AS customer_id,
        full_name,
        email_domain,
        ws_web_site_sk AS web_site_sk,
        ws_sold_date_sk,
        total_sales,
        orders_cnt
    FROM returns_agg
) combined
ORDER BY total_sales DESC
LIMIT 100

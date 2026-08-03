/* goal: Compare daily sales from physical stores and the web, enrich with customer email domains, filter for .com addresses from gmail and compute running totals, previous‑day sales and a global row number. */
WITH
store_daily AS (
    SELECT
        d.d_date,
        d.d_year,
        c.c_customer_sk,
        c.c_email_address,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(ss.ss_ext_sales_price) AS store_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY
        d.d_date,
        d.d_year,
        c.c_customer_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name
),
web_daily AS (
    SELECT
        d.d_date,
        d.d_year,
        c.c_customer_sk,
        c.c_email_address,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(ws.ws_ext_sales_price) AS web_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        d.d_date,
        d.d_year,
        c.c_customer_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name
)
SELECT
    COALESCE(sd.d_date, wd.d_date)                         AS sale_date,
    COALESCE(sd.d_year, wd.d_year)                         AS year,
    COALESCE(sd.c_customer_sk, wd.c_customer_sk)           AS customer_sk,
    COALESCE(sd.customer_name, wd.customer_name)           AS customer_name,
    COALESCE(sd.c_email_address, wd.c_email_address)       AS email,
    sd.store_sales,
    wd.web_sales,
    (COALESCE(sd.store_sales, 0) + COALESCE(wd.web_sales, 0)) AS total_sales,
    regexp_extract(COALESCE(sd.c_email_address, wd.c_email_address), '@([^.]*)\\.', 1) AS email_domain,
    sum(COALESCE(sd.store_sales, 0) + COALESCE(wd.web_sales, 0))
        OVER (ORDER BY COALESCE(sd.d_date, wd.d_date)
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales,
    lag(COALESCE(sd.store_sales, 0) + COALESCE(wd.web_sales, 0))
        OVER (ORDER BY COALESCE(sd.d_date, wd.d_date)) AS prev_day_sales,
    row_number() OVER (ORDER BY COALESCE(sd.d_date, wd.d_date)) AS row_num
FROM store_daily sd
FULL OUTER JOIN web_daily wd
    ON sd.d_date = wd.d_date
WHERE regexp_like(COALESCE(sd.c_email_address, wd.c_email_address), '^[A-Za-z0-9._%+-]+@.*\\.com$')
  AND regexp_extract(COALESCE(sd.c_email_address, wd.c_email_address), '@([^.]*)\\.', 1) LIKE 'gmail%'
ORDER BY sale_date
LIMIT 100

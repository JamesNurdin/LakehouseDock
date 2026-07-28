WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        c.c_email_address,
        s.s_store_name,
        s.s_city,
        d.d_year
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        d.d_year = 2021
        AND s.s_city LIKE 'A%'
        AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
)
SELECT
    s.s_store_name,
    s.s_city,
    CONCAT(s.s_store_name, ' - ', s.s_city) AS store_label,
    regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
    SUM(f.ss_net_profit) AS total_net_profit,
    COUNT(*) AS total_sales,
    AVG(f.ss_quantity) AS avg_quantity,
    SUM(f.ss_ext_sales_price) AS total_sales_amount
FROM
    filtered_sales f
    JOIN store s ON f.ss_store_sk = s.s_store_sk
    JOIN customer c ON f.ss_customer_sk = c.c_customer_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    CONCAT(s.s_store_name, ' - ', s.s_city),
    regexp_extract(c.c_email_address, '@([^.]*)\\.', 1)
ORDER BY
    total_net_profit DESC
LIMIT 100

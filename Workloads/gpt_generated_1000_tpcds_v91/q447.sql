WITH unioned AS (
    SELECT
        s.s_store_name AS store_name,
        concat(s.s_city, '-', CAST(d.d_year AS VARCHAR)) AS city_year_key,
        d.d_year AS sales_year,
        regexp_extract(s.s_market_desc, '^(\\w+)', 1) AS market_first_word,
        SUM(ss.ss_ext_sales_price) AS total_amount,
        'sale' AS transaction_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        regexp_like(s.s_store_name, '.*(Valley|Grove).*')
        AND c.c_email_address LIKE '%@example.com%'
        AND EXISTS (
            SELECT 1
            FROM store_sales ss_check
            JOIN date_dim d_check ON ss_check.ss_sold_date_sk = d_check.d_date_sk
            WHERE ss_check.ss_store_sk = s.s_store_sk
              AND d_check.d_year = 1998
        )
    GROUP BY
        s.s_store_name,
        s.s_city,
        d.d_year,
        s.s_market_desc
    UNION
    SELECT
        s.s_store_name AS store_name,
        concat(s.s_city, '-', CAST(d.d_year AS VARCHAR)) AS city_year_key,
        d.d_year AS sales_year,
        regexp_extract(s.s_market_desc, '^(\\w+)', 1) AS market_first_word,
        SUM(sr.sr_refunded_cash - sr.sr_net_loss) AS total_amount,
        'return' AS transaction_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE
        regexp_like(s.s_store_name, '.*(Valley|Grove).*')
        AND c.c_email_address LIKE '%@example.com%'
        AND EXISTS (
            SELECT 1
            FROM store_sales ss_check
            JOIN date_dim d_check ON ss_check.ss_sold_date_sk = d_check.d_date_sk
            WHERE ss_check.ss_store_sk = s.s_store_sk
              AND d_check.d_year = 1998
        )
    GROUP BY
        s.s_store_name,
        s.s_city,
        d.d_year,
        s.s_market_desc
)
SELECT
    max(store_name) AS store_name,
    max(city_year_key) AS city_year_key,
    max(sales_year) AS sales_year,
    max(market_first_word) AS market_first_word,
    transaction_type,
    SUM(total_amount) AS total_amount
FROM unioned
GROUP BY GROUPING SETS (
    (store_name, transaction_type),
    (sales_year, transaction_type),
    (store_name, sales_year, transaction_type),
    (transaction_type)
)
ORDER BY total_amount DESC
LIMIT 100

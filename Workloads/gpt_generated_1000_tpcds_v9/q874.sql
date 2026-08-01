WITH sales AS (
    SELECT
        c.c_current_hdemo_sk,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_ext_sales_price AS amount,
        'sale' AS transaction_type,
        (SELECT MAX(ss2.ss_ext_sales_price)
         FROM store_sales ss2
         WHERE ss2.ss_item_sk = ss.ss_item_sk) AS max_item_sales_price
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_ext_sales_price > 1000
),
returns AS (
    SELECT
        c.c_current_hdemo_sk,
        ss.ss_sold_date_sk AS date_sk,
        -sr.sr_return_amt AS amount,
        'return' AS transaction_type,
        CAST(NULL AS decimal(7,2)) AS max_item_sales_price
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_amt > 100
),
combined AS (
    SELECT
        c_current_hdemo_sk,
        date_sk,
        amount,
        transaction_type,
        max_item_sales_price
    FROM sales
    UNION ALL
    SELECT
        c_current_hdemo_sk,
        date_sk,
        amount,
        transaction_type,
        max_item_sales_price
    FROM returns
)
SELECT
    c_current_hdemo_sk,
    date_sk,
    SUM(amount) AS total_amount,
    CASE
        WHEN SUM(amount) > 0 THEN 'Positive'
        ELSE 'Non-Positive'
    END AS amount_sign,
    COUNT(*) AS transaction_count,
    MAX(max_item_sales_price) AS max_item_sales_price_over_group
FROM combined
GROUP BY CUBE (c_current_hdemo_sk, date_sk)
ORDER BY total_amount DESC
LIMIT 100

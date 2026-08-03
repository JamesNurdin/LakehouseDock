WITH store_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        'store' AS channel,
        ROW_NUMBER() OVER (PARTITION BY 'store' ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rn
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_quantity > 1
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ss.ss_ext_sales_price) > 1000
),
store_top AS (
    SELECT c_customer_sk, c_first_name, c_last_name, total_sales, channel
    FROM store_agg
    WHERE rn <= 5
),
web_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        'web' AS channel,
        ROW_NUMBER() OVER (PARTITION BY 'web' ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rn
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_quantity > 1
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ws.ws_ext_sales_price) > 1000
),
web_top AS (
    SELECT c_customer_sk, c_first_name, c_last_name, total_sales, channel
    FROM web_agg
    WHERE rn <= 5
),
combined AS (
    SELECT * FROM store_top
    UNION ALL
    SELECT * FROM web_top
)
SELECT *
FROM (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_sales,
        channel,
        ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS rank_in_channel
    FROM combined
) t
WHERE rank_in_channel <= 5
ORDER BY channel, rank_in_channel
LIMIT 100

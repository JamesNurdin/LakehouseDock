WITH store_data AS (
    SELECT
        'store' AS sales_channel,
        s.s_store_id AS channel_id,
        i.i_item_id AS item_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, i.i_item_id
),
web_data AS (
    SELECT
        'web' AS sales_channel,
        CAST(ws.ws_web_page_sk AS VARCHAR) AS channel_id,
        i.i_item_id AS item_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM web_sales ws TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_web_page_sk, i.i_item_id
)
SELECT DISTINCT
    sales_channel,
    channel_id,
    item_id,
    total_sales,
    profit_flag
FROM (
    SELECT * FROM store_data
    UNION
    SELECT * FROM web_data
) combined
ORDER BY total_sales DESC
LIMIT 100

WITH store_data AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_item_sk,
        i.i_product_name,
        ss.ss_ext_sales_price AS total_sales,
        ss.ss_net_profit AS profit,
        CASE
            WHEN ss.ss_net_profit / NULLIF(ss.ss_ext_sales_price, 0) > 0.2 THEN 'High'
            WHEN ss.ss_net_profit / NULLIF(ss.ss_ext_sales_price, 0) > 0.1 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        'Store' AS sales_channel,
        p.p_promo_name
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
      AND i.i_category = 'Sports'
),
web_data AS (
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_item_sk,
        i.i_product_name,
        ws.ws_ext_sales_price AS total_sales,
        ws.ws_net_profit AS profit,
        CASE
            WHEN ws.ws_net_profit / NULLIF(ws.ws_ext_sales_price, 0) > 0.2 THEN 'High'
            WHEN ws.ws_net_profit / NULLIF(ws.ws_ext_sales_price, 0) > 0.1 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        'Web' AS sales_channel,
        p.p_promo_name
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND i.i_category = 'Sports'
)
SELECT
    sold_date_sk,
    ss_item_sk AS item_sk,
    i_product_name,
    total_sales,
    profit,
    profit_category,
    sales_channel,
    p_promo_name
FROM (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
) AS combined
ORDER BY total_sales DESC
LIMIT 100

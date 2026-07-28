/* goal: Compare high‑value sales from physical stores and the web channel during business hours for a specific brand, and list the top transactions */
WITH store_sales_data AS (
    SELECT
        ss.ss_sold_date_sk AS sales_date_sk,
        ss.ss_sold_time_sk AS sales_time_sk,
        i.i_item_id,
        'store' AS channel,
        ss.ss_net_paid AS sales_amount
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'Brand#23'
      AND ss.ss_net_paid > 20
),
web_sales_data AS (
    SELECT
        ws.ws_sold_date_sk AS sales_date_sk,
        ws.ws_sold_time_sk AS sales_time_sk,
        i.i_item_id,
        'web' AS channel,
        ws.ws_net_paid AS sales_amount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'Brand#23'
      AND wp.wp_link_count > 5
      AND ws.ws_net_paid > 20
)
SELECT *
FROM store_sales_data
UNION ALL
SELECT *
FROM web_sales_data
ORDER BY sales_amount DESC
LIMIT 100

WITH latest_inventory AS (
    SELECT inv_item_sk,
           max(inv_quantity_on_hand) AS max_qty
    FROM inventory
    GROUP BY inv_item_sk
),
filtered_sales AS (
    SELECT ws.ws_order_number,
           ws.ws_net_profit,
           ws.ws_item_sk,
           ws.ws_web_page_sk,
           i.i_item_desc,
           wp.wp_url,
           cd.cd_gender
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(wp.wp_url, '^https?://[^/]*?/sports/.*')
      AND i.i_item_desc LIKE '%size%'
      AND cd.cd_gender = 'M'
)
SELECT
    fs.wp_url,
    regexp_extract(fs.wp_url, 'sports/([^/]+)', 1) AS sport_category,
    COUNT(DISTINCT fs.ws_order_number) AS order_cnt,
    SUM(fs.ws_net_profit) AS total_profit,
    li.max_qty AS max_quantity_on_hand
FROM filtered_sales fs
JOIN latest_inventory li ON li.inv_item_sk = fs.ws_item_sk
GROUP BY
    fs.wp_url,
    regexp_extract(fs.wp_url, 'sports/([^/]+)', 1),
    li.max_qty
ORDER BY total_profit DESC
LIMIT 100

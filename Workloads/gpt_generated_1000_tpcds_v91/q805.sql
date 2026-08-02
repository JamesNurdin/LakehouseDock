WITH date_filter AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2000
)
SELECT i_item_id
FROM (
    SELECT i.i_item_id
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_filter df ON ss.ss_sold_date_sk = df.d_date_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY i.i_item_id
) AS store_items
INTERSECT
SELECT i_item_id
FROM (
    SELECT i.i_item_id
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_filter df ON ws.ws_sold_date_sk = df.d_date_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY i.i_item_id
) AS web_items
ORDER BY i_item_id
LIMIT 100

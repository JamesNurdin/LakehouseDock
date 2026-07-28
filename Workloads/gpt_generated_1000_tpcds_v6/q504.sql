WITH store_agg AS (
    SELECT
        i.i_item_id AS item_id,
        ss.ss_sold_date_sk AS sold_date_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY i.i_item_id, ss.ss_sold_date_sk
),
web_agg AS (
    SELECT
        i.i_item_id AS item_id,
        ws.ws_sold_date_sk AS sold_date_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY i.i_item_id, ws.ws_sold_date_sk
),
unioned AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    item_id,
    sold_date_sk,
    sales_channel,
    total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY total_net_paid DESC) AS rn
FROM unioned
ORDER BY total_net_paid DESC, item_id
LIMIT 100

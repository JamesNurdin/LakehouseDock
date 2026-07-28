WITH cs AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_radio = 'N'
    GROUP BY cs.cs_item_sk
),
ws AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        'web' AS channel
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_event = 'N'
    GROUP BY ws.ws_item_sk
),
combined AS (
    SELECT * FROM cs
    UNION ALL
    SELECT * FROM ws
),
ranked AS (
    SELECT
        c.item_sk,
        i.i_item_id,
        c.channel,
        c.total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.item_sk ORDER BY c.total_sales DESC) AS sales_rank
    FROM combined c
    JOIN item i ON c.item_sk = i.i_item_sk
)
SELECT DISTINCT
    item_sk,
    i_item_id,
    channel,
    total_sales,
    sales_rank
FROM ranked
ORDER BY total_sales DESC
LIMIT 100

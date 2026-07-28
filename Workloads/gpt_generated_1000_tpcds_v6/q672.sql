WITH catalog_sales_agg AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 20
      AND (p.p_channel_radio = 'N' OR p.p_channel_radio IS NULL)
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
web_sales_agg AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 20
      AND (p.p_channel_radio = 'N' OR p.p_channel_radio IS NULL)
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
combined_sales AS (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
)
SELECT
    cs.item_sk,
    cs.item_id,
    cs.product_name,
    cs.total_sales
FROM combined_sales cs
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_item_sk = cs.item_sk
)
ORDER BY cs.total_sales DESC
LIMIT 100

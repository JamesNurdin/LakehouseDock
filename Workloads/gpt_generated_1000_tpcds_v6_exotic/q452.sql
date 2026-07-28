WITH catalog_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'Catalog' AS sales_channel,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE i.i_class = 'swimwear'
      AND p.p_channel_email = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_item_id, i.i_product_name
),
web_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'Web' AS sales_channel,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE i.i_class = 'swimwear'
      AND p.p_channel_email = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY total_net_paid DESC
LIMIT 100
